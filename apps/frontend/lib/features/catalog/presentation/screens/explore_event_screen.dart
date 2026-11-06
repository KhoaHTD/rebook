import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/explore_events.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Trang một bộ sưu tập: banner lớn có bìa, mô tả, số cuốn; chip sắp xếp; lưới 3 sách mỗi hàng trên điện thoại.
class ExploreEventScreen extends ConsumerStatefulWidget {
  const ExploreEventScreen({super.key, required this.kindName});

  /// Khoá của bộ sưu tập trong đường dẫn (xem `ExploreEvent.key`).
  final String kindName;

  @override
  ConsumerState<ExploreEventScreen> createState() => _ExploreEventScreenState();
}

class _ExploreEventScreenState extends ConsumerState<ExploreEventScreen> {
  ListingSort _sort = ListingSort.popular;

  List<Listing> _sorted(List<Listing> items) {
    final list = [...items];
    switch (_sort) {
      case ListingSort.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case ListingSort.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case ListingSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ListingSort.popular || ListingSort.relevance:
        // Thứ tự gốc của bộ sưu tập (đã xếp theo phổ biến / theo tiêu chí của bộ).
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final events = ref.watch(exploreEventsProvider);
    final key = widget.kindName.contains('%')
        ? Uri.decodeComponent(widget.kindName)
        : widget.kindName;
    return AppPage(
      title: l10n.exploreBlockCollections,
      showBack: true,
      onRefresh: () => ref.refresh(exploreEventsProvider.future),
      children: [
        AsyncValueView(
          value: events,
          onRetry: () => ref.invalidate(exploreEventsProvider),
          data: (list) {
            final event = list.where((e) => e.key == key).firstOrNull;
            if (event == null) {
              return EmptyState(
                icon: Icons.celebration_outlined,
                title: l10n.nothingToDo,
              );
            }
            final items = _sorted(event.listings);
            final sorts = [
              (ListingSort.popular, l10n.sortPopular),
              (ListingSort.priceAsc, l10n.sortPriceAsc),
              (ListingSort.newest, l10n.sortNewest),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExploreEventCard(
                  event: event,
                  style: EventCardStyle.hero,
                  height: 236,
                  tappable: false,
                ),
                const SizedBox(height: AppSpacing.lg),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (s, label) in sorts)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _sort == s,
                            onSelected: (_) => setState(() => _sort = s),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PosterGrid(
                  compactColumns: 3,
                  children: [
                    for (final l in items)
                      ListingTile(
                        listing: l,
                        compact: context.windowSize.isCompact,
                        onTap: () => context.go(Routes.listing(l.id)),
                      ),
                  ],
                ),
                const SizedBox(height: 110),
              ],
            );
          },
        ),
      ],
    );
  }
}
