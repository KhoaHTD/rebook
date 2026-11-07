import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Admin đối soát COD: hãng vận chuyển đã thu hộ tiền, sàn nhận đủ rồi mới trả shop.
class CodScreen extends ConsumerWidget {
  const CodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final pending = ref.watch(adminCodPendingProvider);
    final busy = ref.watch(adminActionsProvider).isLoading;

    return AppPage(
      title: l10n.admCodTitle,
      showBack: false,
      onRefresh: () => ref.refresh(adminCodPendingProvider.future),
      children: [
        Text(l10n.admCodHint, style: text.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        AsyncValueView(
          value: pending,
          onRetry: () => ref.invalidate(adminCodPendingProvider),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.payments_outlined,
                  title: l10n.nothingToDo,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    children: [
                      for (final o in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: InfoPanel(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            // Hẹp (điện thoại): nút xuống dưới thông tin đơn thay vì ép mã đơn thành từng ký tự.
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final narrow = box.maxWidth < 460;
                                Widget side(Widget w) =>
                                    narrow ? w : Expanded(child: w);
                                return Flex(
                                  direction: narrow
                                      ? Axis.vertical
                                      : Axis.horizontal,
                                  crossAxisAlignment: narrow
                                      ? CrossAxisAlignment.stretch
                                      : CrossAxisAlignment.center,
                                  children: [
                                    side(
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(o.code, style: text.titleSmall),
                                          Text(
                                            formatVnd(o.total),
                                            style: text.bodyMedium,
                                          ),
                                          if (o.deliveredAt != null)
                                            Text(
                                              l10n.admCodDeliveredAt(
                                                formatShortDateTime(
                                                  o.deliveredAt!,
                                                ),
                                              ),
                                              style: text.bodySmall,
                                            ),
                                          if (o.refundPending)
                                            Text(
                                              l10n.admCodRefundPending,
                                              style: text.bodySmall?.copyWith(
                                                color: c.warning,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: AppSpacing.md,
                                      height: AppSpacing.md,
                                    ),
                                    FilledButton(
                                      onPressed: busy
                                          ? null
                                          : () async {
                                              final ok = await confirmDialog(
                                                context,
                                                l10n.admCodConfirmQuestion(
                                                  formatVnd(o.total),
                                                ),
                                              );
                                              if (!ok) return;
                                              if (!context.mounted) return;
                                              final done = await ref
                                                  .read(
                                                    adminActionsProvider
                                                        .notifier,
                                                  )
                                                  .remitCod(o.orderId, o.total);
                                              if (!context.mounted) return;
                                              if (done) {
                                                showInfoSnack(
                                                  context,
                                                  l10n.admCodDone,
                                                );
                                              } else {
                                                showErrorSnack(
                                                  context,
                                                  ref
                                                      .read(
                                                        adminActionsProvider,
                                                      )
                                                      .error!,
                                                );
                                              }
                                            },
                                      child: Text(l10n.admCodConfirm),
                                    ),
                                  ],
                                );
                              },
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
