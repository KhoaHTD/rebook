import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/seller/presentation/providers/seller_providers.dart';
import 'package:book_marketplace/features/seller/presentation/widgets/seller_widgets.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Quản lý tin đăng: lọc theo trạng thái, sửa, ẩn / hiện, xóa (SRS 4.1).
class SellerListingsScreen extends ConsumerStatefulWidget {
  const SellerListingsScreen({super.key});

  @override
  ConsumerState<SellerListingsScreen> createState() =>
      _SellerListingsScreenState();
}

class _SellerListingsScreenState extends ConsumerState<SellerListingsScreen> {
  ListingStatus? _status;

  Future<void> _onMenu(Listing listing, String action) async {
    final l10n = context.l10n;
    final actions = ref.read(sellerActionsProvider.notifier);
    switch (action) {
      case 'edit':
        context.go(Routes.editListing(listing.id));
        return;
      case 'toggle':
        await actions.setVisible(
          listing.id,
          visible: listing.status == ListingStatus.hidden,
        );
      case 'delete':
        if (!await confirmDialog(context, l10n.deleteListingConfirm)) return;
        await actions.deleteListing(listing.id);
    }
    if (!mounted) return;
    final error = ref.read(sellerActionsProvider).error;
    if (error != null) showErrorSnack(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listings = ref.watch(sellerListingsProvider);
    return AppPage(
      title: l10n.myListings,
      showBack: true,
      onRefresh: () => ref.refresh(sellerListingsProvider.future),
      actions: [
        FilledButton.icon(
          onPressed: () => context.go(Routes.newListing),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.newListing),
        ),
      ],
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in [null, ...ListingStatus.values])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(s == null ? l10n.ordersAll : s.label(l10n)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AsyncValueView(
          value: listings,
          onRetry: () => ref.invalidate(sellerListingsProvider),
          data: (all) {
            final list = all
                .where((l) => _status == null || l.status == _status)
                .toList();
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.menu_book_outlined,
                title: l10n.noListings,
                action: FilledButton(
                  onPressed: () => context.go(Routes.newListing),
                  child: Text(l10n.newListing),
                ),
              );
            }
            return PosterGrid(
              children: [
                for (final l in list)
                  SellerListingTile(
                    listing: l,
                    onTap: () => context.go(Routes.editListing(l.id)),
                    onMenuSelected: (v) => _onMenu(l, v),
                    menu: [
                      PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                      if (l.status != ListingStatus.pendingReview &&
                          l.status != ListingStatus.rejected)
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            l.status == ListingStatus.hidden
                                ? l10n.showListing
                                : l10n.hideListing,
                          ),
                        ),
                      PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                    ],
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
