import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/domain/explore_event.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/explore_events.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/listing_tile.dart';
import 'package:book_marketplace/shared/widgets/poster_grid.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Danh sách sách của một sự kiện ở trang Khám phá.
class ExploreEventScreen extends ConsumerWidget {
  const ExploreEventScreen({super.key, required this.kindName});

  /// Tên của [ExploreEventKind] trong đường dẫn.
  final String kindName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final events = ref.watch(exploreEventsProvider);
    final kind = ExploreEventKind.values.asNameMap()[kindName];
    return AppPage(
      title: l10n.exploreEventsTitle,
      showBack: true,
      onRefresh: () => ref.refresh(exploreEventsProvider.future),
      children: [
        AsyncValueView(
          value: events,
          onRetry: () => ref.invalidate(exploreEventsProvider),
          data: (list) {
            final event = list.where((e) => e.kind == kind).firstOrNull;
            if (event == null) {
              return EmptyState(
                icon: Icons.celebration_outlined,
                title: l10n.nothingToDo,
              );
            }
            final t = exploreEventText(context, event);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.subtitle,
                  style: text.bodyMedium?.copyWith(color: c.secondaryText),
                ),
                const SizedBox(height: AppSpacing.lg),
                PosterGrid(
                  children: [
                    for (final l in event.listings)
                      ListingTile(
                        listing: l,
                        showShop: true,
                        onTap: () => context.go(Routes.listing(l.id)),
                      ),
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
