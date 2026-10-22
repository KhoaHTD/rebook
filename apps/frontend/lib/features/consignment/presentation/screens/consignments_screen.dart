import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/consignment/presentation/providers/consignment_providers.dart';
import 'package:book_marketplace/shared/domain/rules.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Các yêu cầu ký gửi đấu giá của tôi (SRS 6.1).
class ConsignmentsScreen extends ConsumerWidget {
  const ConsignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(myConsignmentsProvider);
    const fees = FeeConfig();
    return AppPage(
      title: l10n.consignTitle,
      subtitle: l10n.consignIntro(fees.sellerCommissionPercent.round()),
      onRefresh: () => ref.refresh(myConsignmentsProvider.future),
      actions: [
        HeaderAction(
          icon: Icons.add_rounded,
          label: l10n.newConsignment,
          onPressed: () => context.go(Routes.newConsignment),
        ),
      ],
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(myConsignmentsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.noConsignments,
                  action: FilledButton(
                    onPressed: () => context.go(Routes.newConsignment),
                    child: Text(l10n.newConsignment),
                  ),
                )
              : PosterGrid(
                  children: [
                    for (final c in items)
                      PosterTile(
                        poster: BookPoster(
                          title: c.book.title,
                          author: c.book.author,
                          coverUrl: c.book.coverUrl,
                          seed: c.book.id,
                        ),
                        title: c.book.title,
                        onTap: () => context.go(Routes.consignment(c.id)),
                        meta: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.expectedPrice}: ${formatVnd(c.expectedPrice)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            StatusPill(
                              c.status.label(l10n),
                              tone: c.status.tone,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
