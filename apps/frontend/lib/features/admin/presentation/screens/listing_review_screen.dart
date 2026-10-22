import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Duyệt tin đăng của shop chưa đủ uy tín (SRS 4.1).
class ListingReviewScreen extends ConsumerWidget {
  const ListingReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final list = ref.watch(pendingListingsProvider);
    final busy = ref.watch(adminActionsProvider).isLoading;

    Future<void> review(String id, {required bool approve}) async {
      String? reason;
      if (!approve) {
        reason = await showCancelSheet(
          context,
          l10n.listingRejectReasons,
          title: l10n.rejectReasonTitle,
        );
        if (reason == null) return;
      }
      await ref.read(adminActionsProvider.notifier).run(
        (r) => r.reviewListing(id, approve: approve, reason: reason),
        [DataArea.listings],
      );
      if (!context.mounted) return;
      final error = ref.read(adminActionsProvider).error;
      if (error != null) showErrorSnack(context, error);
    }

    return AppPage(
      title: l10n.navListingReview,
      showBack: false,
      onRefresh: () => ref.refresh(pendingListingsProvider.future),
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(pendingListingsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: l10n.nothingToDo,
                )
              : Column(
                  children: [
                    for (final l in items)
                      _ReviewCard(
                        listing: l,
                        actions: [
                          OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => review(l.id, approve: false),
                            child: Text(l10n.reject),
                          ),
                          FilledButton(
                            onPressed: busy
                                ? null
                                : () => review(l.id, approve: true),
                            child: Text(l10n.approve),
                          ),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.listing, required this.actions});

  final Listing listing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final l = listing;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InfoPanel(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.book.title, style: context.textStyles.titleLarge),
            Text(
              '${l.book.author} · ${l.shop.name}',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.appColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusPill(
                  l.book.condition.label(l10n),
                  tone: l.book.condition.tone,
                ),
                PriceText(l.price),
              ],
            ),
            if (l.book.images.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              PhotoStrip(urls: [for (final i in l.book.images) i.url]),
            ],
            if (l.book.description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.book.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.sm, children: actions),
          ],
        ),
      ),
    );
  }
}
