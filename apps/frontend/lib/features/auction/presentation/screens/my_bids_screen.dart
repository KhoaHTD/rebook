import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_floor_providers.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Lịch sử trả giá của tôi: lô nào, trả bao nhiêu, lúc nào, đang dẫn đầu hay đã bị vượt.
class MyBidsScreen extends ConsumerWidget {
  const MyBidsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final bids = ref.watch(myBidsProvider);
    return AppPage(
      title: l10n.myBids,
      showBack: true,
      onRefresh: () => ref.refresh(myBidsProvider.future),
      children: [
        AsyncValueView(
          value: bids,
          onRetry: () => ref.invalidate(myBidsProvider),
          data: (list) => list.isEmpty
              ? EmptyState(icon: Icons.gavel_rounded, title: l10n.myBidsEmpty)
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: [
                      for (final b in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: InkWell(
                            borderRadius: AppRadius.card,
                            onTap: () => context.go(Routes.lot(b.lot.id)),
                            child: InfoPanel(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b.lot.book.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.textStyles.titleMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.myBidLine(
                                            b.bid.paddleNumber,
                                            formatVnd(b.bid.amount),
                                          ),
                                          style: context.textStyles.bodyMedium,
                                        ),
                                        Text(
                                          formatDateTime(b.bid.createdAt),
                                          style: context.textStyles.bodySmall
                                              ?.copyWith(
                                                color: c.secondaryText,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    b.leading
                                        ? l10n.bidLeading
                                        : l10n.bidOutbid,
                                    style: context.textStyles.labelMedium
                                        ?.copyWith(
                                          color: b.leading ? c.success : c.live,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
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
