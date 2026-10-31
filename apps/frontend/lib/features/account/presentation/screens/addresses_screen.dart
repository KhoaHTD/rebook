import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/account/presentation/providers/account_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Địa chỉ của tôi: danh sách (tên | số điện thoại, địa chỉ, nhãn Mặc định / Văn phòng), bấm một dòng để sửa,
/// nút "Thêm địa chỉ mới" ghim ở đáy.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final list = ref.watch(addressBookProvider);
    return AppPage(
      title: l10n.addresses,
      showBack: true,
      bottomBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: OutlinedButton.icon(
            onPressed: () => context.push(Routes.addressNew),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addrAddNew),
          ),
        ),
      ),
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(addressBookProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.location_off_outlined,
                  title: l10n.noAddresses,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: InfoPanel(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final (i, a) in items.indexed) ...[
                          if (i > 0)
                            Divider(height: 1, indent: 16, color: c.separator),
                          InkWell(
                            onTap: () => context.push(Routes.addressEdit(a.id)),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            text: a.receiver,
                                            style: text.titleMedium,
                                            children: [
                                              TextSpan(
                                                text: '  |  ${a.phone}',
                                                style: text.bodyMedium
                                                    ?.copyWith(
                                                      color: c.secondaryText,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          a.detail,
                                          style: text.bodyMedium?.copyWith(
                                            color: c.secondaryText,
                                          ),
                                        ),
                                        Text(
                                          [a.ward, a.district, a.province]
                                              .where((s) => s.isNotEmpty)
                                              .join(', '),
                                          style: text.bodyMedium?.copyWith(
                                            color: c.secondaryText,
                                          ),
                                        ),
                                        if (a.isDefault ||
                                            a.type == AddressType.office) ...[
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: AppSpacing.sm,
                                            children: [
                                              if (a.isDefault)
                                                PillBadge(l10n.defaultBadge),
                                              if (a.type == AddressType.office)
                                                PillBadge(l10n.addrTypeOffice),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: c.tertiaryText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
