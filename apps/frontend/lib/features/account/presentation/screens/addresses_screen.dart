import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/account/presentation/providers/account_providers.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Sổ địa chỉ giao hàng: thêm, sửa, xoá, đặt mặc định.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [Address? a]) async {
    final saved = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddressSheet(address: a),
    );
    if (saved == null) return;
    final ok = await ref
        .read(accountControllerProvider.notifier)
        .saveAddress(saved);
    if (!ok && context.mounted) {
      showErrorSnack(context, ref.read(accountControllerProvider).error!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(addressBookProvider);
    return AppPage(
      title: l10n.addresses,
      showBack: true,
      actions: [
        IconButton(
          tooltip: l10n.addAddress,
          icon: const Icon(Icons.add_rounded),
          onPressed: () => _edit(context, ref),
        ),
      ],
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(addressBookProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.location_off_outlined,
                  title: l10n.noAddresses,
                  action: FilledButton(
                    onPressed: () => _edit(context, ref),
                    child: Text(l10n.addAddress),
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      for (final a in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InfoPanel(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${a.receiver} · ${a.phone}',
                                              style: context
                                                  .textStyles
                                                  .titleMedium,
                                            ),
                                          ),
                                          if (a.isDefault) ...[
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            PillBadge(l10n.defaultBadge),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        a.oneLine,
                                        style: context.textStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                DotsButton(
                                  compact: true,
                                  items: [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(l10n.edit),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(l10n.delete),
                                    ),
                                  ],
                                  onSelected: (v) async {
                                    if (v == 'edit') {
                                      return _edit(context, ref, a);
                                    }
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (d) => AlertDialog(
                                        content: Text(
                                          l10n.deleteAddressConfirm,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(d, false),
                                            child: Text(l10n.cancel),
                                          ),
                                          FilledButton(
                                            onPressed: () =>
                                                Navigator.pop(d, true),
                                            child: Text(l10n.delete),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok ?? false) {
                                      await ref
                                          .read(
                                            accountControllerProvider.notifier,
                                          )
                                          .deleteAddress(a.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({this.address});

  final Address? address;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  final _form = GlobalKey<FormState>();
  late final _fields = {
    for (final k in [
      'receiver',
      'phone',
      'province',
      'district',
      'ward',
      'detail',
    ])
      k: TextEditingController(
        text: switch (k) {
          'receiver' => widget.address?.receiver,
          'phone' => widget.address?.phone,
          'province' => widget.address?.province,
          'district' => widget.address?.district,
          'ward' => widget.address?.ward,
          _ => widget.address?.detail,
        },
      ),
  };
  late var _default = widget.address?.isDefault ?? false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = {
      'receiver': l10n.addressReceiver,
      'phone': l10n.phone,
      'province': l10n.addressProvince,
      'district': l10n.addressDistrict,
      'ward': l10n.addressWard,
      'detail': l10n.addressDetail,
    };
    String v(String k) => _fields[k]!.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.address == null ? l10n.newAddress : l10n.editAddress,
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final e in labels.entries) ...[
                TextFormField(
                  controller: _fields[e.key],
                  decoration: InputDecoration(labelText: e.value),
                  keyboardType: e.key == 'phone' ? TextInputType.phone : null,
                  validator: (x) =>
                      (x ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.addressDefault),
                value: _default,
                onChanged: (x) => setState(() => _default = x),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    Address(
                      id: widget.address?.id ?? '',
                      receiver: v('receiver'),
                      phone: v('phone'),
                      province: v('province'),
                      district: v('district'),
                      ward: v('ward'),
                      detail: v('detail'),
                      isDefault: _default,
                    ),
                  );
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
