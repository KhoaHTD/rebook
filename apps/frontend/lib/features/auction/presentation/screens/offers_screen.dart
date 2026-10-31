import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/second_chance_providers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Lời mời mua lần hai (SRS 6.6): người thắng bỏ thanh toán thì người trả giá cao thứ hai (giá ≥ giá sàn) được mời mua
/// với giá đã trả trong 24 giờ.
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final offers = ref.watch(secondChanceOffersProvider);
    final busy = ref.watch(secondChanceActionsProvider).isLoading;
    final actions = ref.read(secondChanceActionsProvider.notifier);

    Future<void> accept(SecondChanceOffer o) async {
      final order = await actions.accept(o.id);
      if (!context.mounted) return;
      final error = ref.read(secondChanceActionsProvider).error;
      if (error != null || order == null) {
        return showErrorSnack(context, error ?? Exception());
      }
      showInfoSnack(context, l10n.offerAccepted);
      context.go(Routes.auctionOrder(order.id));
    }

    Future<void> decline(SecondChanceOffer o) async {
      if (!await confirmDialog(context, l10n.offerDeclineQuestion)) return;
      final ok = await actions.decline(o.id);
      if (!context.mounted || ok) return;
      showErrorSnack(context, ref.read(secondChanceActionsProvider).error!);
    }

    return AppPage(
      title: l10n.offersTitle,
      showBack: true,
      onRefresh: () => ref.refresh(secondChanceOffersProvider.future),
      children: [
        Text(l10n.offersHint, style: context.textStyles.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: offers,
          onRetry: () => ref.invalidate(secondChanceOffersProvider),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.local_offer_outlined,
                  title: l10n.offersEmpty,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: [
                      for (final o in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _OfferCard(
                            offer: o,
                            busy: busy,
                            onAccept: () => accept(o),
                            onDecline: () => decline(o),
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final SecondChanceOffer offer;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final c = context.appColors;
    final pending = offer.status == SecondChanceStatus.pending;
    return InfoPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (offer.coverUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 56,
                    height: 80,
                    child: AppImage(offer.coverUrl!),
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.bookTitle, style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      l10n.offerLotLine(
                        offer.lotNumber,
                        formatVnd(offer.amount),
                      ),
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.offerExpires(formatDateTime(offer.expiresAt)),
                      style: text.bodySmall?.copyWith(color: c.secondaryText),
                    ),
                  ],
                ),
              ),
              StatusPill(offer.status.label(l10n), tone: offer.status.tone),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onAccept,
                    child: Text(l10n.offerAccept),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: busy ? null : onDecline,
                  child: Text(l10n.offerDecline),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
