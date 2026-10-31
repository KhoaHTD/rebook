import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/core/network/admin_units.dart';
import 'package:book_marketplace/core/network/geocoder.dart';
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
import 'package:book_marketplace/shared/widgets/osm_map.dart';

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
    _debounce?.cancel();
    for (final c in [_receiver, _phone, _district, _ward, _detail]) {
      c.dispose();
    }
    super.dispose();
  }

  Timer? _debounce;
  var _locating = false;
  var _notFound = false;

  /// Người dùng đã tự chạm bản đồ: không tự định vị đè lên nữa (vẫn bấm nút được).
  var _manualPin = false;

  /// Gõ xong (ngừng 1,5 giây) thì tự định vị theo địa chỉ; Nominatim giới hạn 1 yêu cầu / giây.
  void _scheduleLocate() {
    _debounce?.cancel();
    if (_province.isEmpty || _manualPin) return;
    _debounce = Timer(const Duration(milliseconds: 1500), _locate);
  }

  /// Số thứ tự lần định vị mới nhất: kết quả của lần cũ (đã đổi địa chỉ giữa chừng) bị bỏ.
  var _locateTicket = 0;

  Future<void> _locate() async {
    if (_province.isEmpty || !mounted) return;
    final ticket = ++_locateTicket;
    setState(() {
      _locating = true;
      _notFound = false;
    });
    final hit = await ref.read(geocoderProvider).locate((
      street: _detail.text,
      ward: _ward.text,
      district: _district.text,
      province: _province,
    ));
    if (!mounted || ticket != _locateTicket) return;
    setState(() {
      _locating = false;
      _notFound = hit == null;
      if (hit != null) {
        _lat = hit.$1;
        _lon = hit.$2;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Địa chỉ chưa có ghim thì tự định vị một lần khi mở.
    if (widget.address != null && _point == null) _scheduleLocate();
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
    if (picked != null && picked != _province) {
      setState(() {
        _province = picked;
        _district.clear();
        _ward.clear();
        _districtCode = null;
      });
      _scheduleLocate();
    }
  }

  /// Mã quận đang chọn (để tra phường / xã). Null khi quận nhập tay hoặc mở địa chỉ cũ: dò lại theo tên.
  int? _districtCode;

  Future<({String name, int? code})?> _openUnitPicker(
    String title,
    String selected,
    Future<List<AdminUnit>> Function() load,
  ) => showModalBottomSheet<({String name, int? code})>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _UnitPicker(title: title, selected: selected, load: load),
  );

  Future<void> _pickDistrict() async {
    if (_province.isEmpty) return;
    final units = ref.read(adminUnitsProvider);
    final picked = await _openUnitPicker(
      context.l10n.addrPickDistrict,
      _district.text,
      () => units.districts(_province),
    );
    if (picked == null) return;
    setState(() {
      _district.text = picked.name;
      _districtCode = picked.code;
      _ward.clear();
    });
    _scheduleLocate();
  }

  Future<void> _pickWard() async {
    if (_district.text.isEmpty) return;
    final units = ref.read(adminUnitsProvider);
    final picked = await _openUnitPicker(
      context.l10n.addrPickWard,
      _ward.text,
      () async {
        var code = _districtCode;
        if (code == null) {
          final key = unitKey(_district.text);
          final all = await units.districts(_province);
          code = all.where((d) => unitKey(d.name) == key).firstOrNull?.code;
          if (code == null) throw StateError('district not found');
          _districtCode = code;
        }
        return units.wards(code);
      },
    );
    if (picked == null) return;
    setState(() => _ward.text = picked.name);
    _scheduleLocate();
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

    Widget selectBox(
      String value,
      String placeholder,
      VoidCallback? onTap,
      bool showError,
    ) => InkWell(
      borderRadius: AppRadius.card,
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          enabled: onTap != null,
          errorText: showError ? placeholder : null,
          suffixIcon: const Icon(Icons.chevron_right_rounded),
        ),
        child: Text(
          value.isEmpty ? placeholder : value,
          style: text.bodyLarge?.copyWith(
            color: value.isEmpty ? c.tertiaryText : null,
          ),
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
                  LabeledField(
                    label: l10n.addressDistrict,
                    child: selectBox(
                      _district.text,
                      _province.isEmpty
                          ? l10n.addrPickProvinceFirst
                          : l10n.addrPickDistrict,
                      _province.isEmpty ? null : _pickDistrict,
                      _submitted && _district.text.isEmpty,
                    ),
                  ),
                  LabeledField(
                    label: l10n.addressWard,
                    child: selectBox(
                      _ward.text,
                      _district.text.isEmpty
                          ? l10n.addrPickDistrictFirst
                          : l10n.addrPickWard,
                      _district.text.isEmpty ? null : _pickWard,
                      _submitted && _ward.text.isEmpty,
                    ),
                  ),
                  RuleField(
                    controller: _detail,
                    rule: Rules.street,
                    label: l10n.addressDetail,
                    onChanged: (_) => _scheduleLocate(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  OsmMap(
                    point: pin,
                    zoom: _point == null ? 8 : 16,
                    onPick: (p) => setState(() {
                      _manualPin = true;
                      _notFound = false;
                      _lat = p.$1;
                      _lon = p.$2;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _locating || _province.isEmpty
                          ? null
                          : () {
                              _manualPin = false;
                              _locate();
                            },
                      icon: _locating
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(
                        _locating ? l10n.addrLocating : l10n.addrLocate,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _notFound
                        ? l10n.addrNotFound
                        : _point != null
                        ? l10n.addrPinned
                        : l10n.addrMapHint,
                    style: text.bodySmall?.copyWith(
                      color: _notFound ? context.colors.error : c.secondaryText,
                    ),
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

/// Chọn quận / huyện hoặc phường / xã từ danh sách tải về, có ô tìm. Tải lỗi thì cho nhập tên thủ công.
class _UnitPicker extends StatefulWidget {
  const _UnitPicker({
    required this.title,
    required this.selected,
    required this.load,
  });

  final String title;
  final String selected;
  final Future<List<AdminUnit>> Function() load;

  @override
  State<_UnitPicker> createState() => _UnitPickerState();
}

class _UnitPickerState extends State<_UnitPicker> {
  final _search = TextEditingController();
  final _manual = TextEditingController();
  late final Future<List<AdminUnit>> _units = widget.load();

  @override
  void dispose() {
    _search.dispose();
    _manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = removeDiacritics(_search.text).toLowerCase().trim();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FutureBuilder<List<AdminUnit>>(
          future: _units,
          builder: (context, snap) {
            final header = Text(
              widget.title,
              style: context.textStyles.titleLarge,
            );
            if (snap.connectionState != ConnectionState.done) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }
            if (snap.hasError || (snap.data ?? const []).isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: AppSpacing.md),
                  Text(l10n.addrUnitsFailed),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _manual,
                    maxLength: 50,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(counterText: ''),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: Rules.district.isValid(_manual.text)
                        ? () => Navigator.pop(context, (
                            name: Rules.district.value(_manual.text),
                            code: null,
                          ))
                        : null,
                    child: Text(l10n.confirm),
                  ),
                ],
              );
            }
            final units = [
              for (final u in snap.data!)
                if (q.isEmpty ||
                    removeDiacritics(u.name).toLowerCase().contains(q))
                  u,
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: l10n.addrSearchUnit,
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: units.isEmpty
                      ? Center(child: Text(l10n.addrUnitsEmpty))
                      : ListView(
                          children: [
                            for (final u in units)
                              ListTile(
                                title: Text(u.name),
                                trailing: u.name == widget.selected
                                    ? const Icon(Icons.check_rounded)
                                    : null,
                                onTap: () => Navigator.pop(context, (
                                  name: u.name,
                                  code: u.code,
                                )),
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
