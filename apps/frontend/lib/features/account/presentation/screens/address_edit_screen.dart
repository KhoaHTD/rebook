import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/vietnamese.dart';
import 'package:book_marketplace/features/account/presentation/providers/account_providers.dart';
import 'package:book_marketplace/shared/data/vietnam_geo.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';
import 'package:book_marketplace/shared/widgets/vietnam_map.dart';

/// Thêm / sửa một địa chỉ: tỉnh (chọn từ danh sách) + quận + phường + số nhà, bản đồ ghim ngay trong trang,
/// thông tin liên hệ, đặt mặc định, loại địa chỉ; ghim ở đáy: Xóa địa chỉ (khi sửa) + Hoàn thành.
class AddressEditScreen extends ConsumerWidget {
  const AddressEditScreen({super.key, this.addressId});

  /// null = thêm mới.
  final String? addressId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final book = ref.watch(addressBookProvider);
    final title = addressId == null ? l10n.newAddress : l10n.editAddress;
    return AsyncValueView(
      value: book,
      onRetry: () => ref.invalidate(addressBookProvider),
      data: (items) {
        final existing = items.where((a) => a.id == addressId).firstOrNull;
        return _AddressForm(
          // Key theo id để đổi sang địa chỉ khác thì dựng lại form.
          key: ValueKey(addressId),
          title: title,
          address: existing,
          isFirst: items.isEmpty,
        );
      },
    );
  }
}

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm({
    super.key,
    required this.title,
    required this.address,
    required this.isFirst,
  });

  final String title;
  final Address? address;

  /// Địa chỉ đầu tiên thì mặc định bật "Đặt làm mặc định".
  final bool isFirst;

  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  late final _receiver = TextEditingController(text: widget.address?.receiver);
  late final _phone = TextEditingController(text: widget.address?.phone);
  late final _district = TextEditingController(text: widget.address?.district);
  late final _ward = TextEditingController(text: widget.address?.ward);
  late final _detail = TextEditingController(text: widget.address?.detail);
  late String _province = widget.address?.province ?? '';
  late bool _default = widget.address?.isDefault ?? widget.isFirst;
  late AddressType _type = widget.address?.type ?? AddressType.home;
  late double? _lat = widget.address?.latitude;
  late double? _lon = widget.address?.longitude;
  var _submitted = false;
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final c in [_receiver, _phone, _district, _ward, _detail]) {
      c.dispose();
    }
    super.dispose();
  }

  GeoPoint? get _point => _lat == null || _lon == null ? null : (_lat!, _lon!);

  bool get _valid =>
      _province.isNotEmpty &&
      Rules.fullName.isValid(_receiver.text) &&
      Rules.phone.isValid(_phone.text) &&
      Rules.district.isValid(_district.text) &&
      Rules.ward.isValid(_ward.text) &&
      Rules.street.isValid(_detail.text);

  Future<void> _pickProvince() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _ProvincePicker(selected: _province),
    );
    if (picked != null) setState(() => _province = picked);
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final formOk = _form.currentState?.validate() ?? false;
    if (!formOk || !_valid) return;
    final saved = Address(
      id: widget.address?.id ?? '',
      receiver: Rules.fullName.value(_receiver.text),
      phone: Rules.phone.value(_phone.text),
      province: _province,
      district: Rules.district.value(_district.text),
      ward: Rules.ward.value(_ward.text),
      detail: Rules.street.value(_detail.text),
      isDefault: _default,
      latitude: _lat,
      longitude: _lon,
      type: _type,
    );
    final ok = await ref
        .read(accountControllerProvider.notifier)
        .saveAddress(saved);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      showErrorSnack(context, ref.read(accountControllerProvider).error!);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text(l10n.deleteAddressConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final done = await ref
        .read(accountControllerProvider.notifier)
        .deleteAddress(widget.address!.id);
    if (!mounted) return;
    if (done) {
      context.pop();
    } else {
      showErrorSnack(context, ref.read(accountControllerProvider).error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final busy = ref.watch(accountControllerProvider).isLoading;
    final centre = _province.isEmpty ? null : VietnamGeo.province(_province);
    final pin = _point ?? centre;

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InfoPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: text.titleSmall),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );

    return AppPage(
      title: widget.title,
      showBack: true,
      bottomBar: PinnedBar(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                if (widget.address != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : _delete,
                      child: Text(l10n.addrDelete),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  flex: widget.address == null ? 1 : 2,
                  child: FilledButton(
                    onPressed: busy ? null : _save,
                    child: Text(l10n.addrDone),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                section(l10n.addrSectionAddress, [
                  LabeledField(
                    label: l10n.addressProvince,
                    child: InkWell(
                      borderRadius: AppRadius.card,
                      onTap: _pickProvince,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          errorText: _submitted && _province.isEmpty
                              ? l10n.addrPickProvince
                              : null,
                          suffixIcon: const Icon(Icons.chevron_right_rounded),
                        ),
                        child: Text(
                          _province.isEmpty ? l10n.addrPickProvince : _province,
                          style: text.bodyLarge?.copyWith(
                            color: _province.isEmpty ? c.tertiaryText : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  RuleField(
                    controller: _district,
                    rule: Rules.district,
                    label: l10n.addressDistrict,
                  ),
                  RuleField(
                    controller: _ward,
                    rule: Rules.ward,
                    label: l10n.addressWard,
                  ),
                  RuleField(
                    controller: _detail,
                    rule: Rules.street,
                    label: l10n.addressDetail,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: Center(
                      child: VietnamMap(
                        point: pin,
                        onPick: (p) => setState(() {
                          _lat = p.$1;
                          _lon = p.$2;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _point != null ? l10n.addrPinned : l10n.addrMapHint,
                    style: text.bodySmall?.copyWith(color: c.secondaryText),
                  ),
                ]),
                section(l10n.addrContact, [
                  RuleField(
                    controller: _receiver,
                    rule: Rules.fullName,
                    label: l10n.addressReceiver,
                  ),
                  RuleField(
                    controller: _phone,
                    rule: Rules.phone,
                    label: l10n.phone,
                    bottom: 0,
                  ),
                ]),
                InfoPanel(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.addressDefault),
                        value: _default,
                        onChanged: (v) => setState(() => _default = v),
                      ),
                      Row(
                        children: [
                          Text('${l10n.addrType}:', style: text.bodyMedium),
                          const Spacer(),
                          for (final t in AddressType.values)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.sm,
                              ),
                              child: ChoiceChip(
                                label: Text(
                                  t == AddressType.office
                                      ? l10n.addrTypeOffice
                                      : l10n.addrTypeHome,
                                ),
                                selected: _type == t,
                                onSelected: (_) => setState(() => _type = t),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Chọn tỉnh / thành từ 63 tỉnh, có ô tìm kiếm (gõ không dấu cũng được).
class _ProvincePicker extends StatefulWidget {
  const _ProvincePicker({required this.selected});

  final String selected;

  @override
  State<_ProvincePicker> createState() => _ProvincePickerState();
}

class _ProvincePickerState extends State<_ProvincePicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = removeDiacritics(_search.text).toLowerCase().trim();
    final names = [
      for (final n in VietnamGeo.provinceNames)
        if (q.isEmpty || removeDiacritics(n).toLowerCase().contains(q)) n,
    ];
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.addrPickProvince, style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.addrSearchProvince,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView(
                children: [
                  for (final n in names)
                    ListTile(
                      title: Text(n),
                      trailing: n == widget.selected
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => Navigator.pop(context, n),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
