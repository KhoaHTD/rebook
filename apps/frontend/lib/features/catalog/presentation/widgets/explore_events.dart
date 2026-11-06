import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/catalog/domain/explore_event.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/explore_sections.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Tiêu đề, mô tả ngắn, biểu tượng và nhãn của từng sự kiện (dùng cho thẻ và trang danh sách).
class ExploreEventText {
  const ExploreEventText({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
}

ExploreEventText exploreEventText(BuildContext context, ExploreEvent e) {
  final l10n = context.l10n;
  return switch (e.kind) {
    ExploreEventKind.cheap => ExploreEventText(
      title: l10n.evCheapTitle(formatVnd(cheapEventMaxPrice)),
      subtitle: l10n.evCheapSub(e.count, formatVnd(e.minPrice)),
      tag: l10n.evTagDeal,
      icon: Icons.sell_rounded,
    ),
    ExploreEventKind.rare => ExploreEventText(
      title: l10n.evRareTitle(rareEventBeforeYear),
      subtitle: l10n.evRareSub(e.count),
      tag: l10n.evTagRare,
      icon: Icons.auto_stories_rounded,
    ),
    ExploreEventKind.likeNew => ExploreEventText(
      title: l10n.evLikeNewTitle,
      subtitle: l10n.evLikeNewSub(e.count),
      tag: l10n.evTagLikeNew,
      icon: Icons.auto_awesome_rounded,
    ),
    ExploreEventKind.vnClassics => ExploreEventText(
      title: l10n.evClassicTitle,
      subtitle: l10n.evClassicSub(e.count),
      tag: l10n.evTagClassic,
      icon: Icons.menu_book_rounded,
    ),
    ExploreEventKind.author => ExploreEventText(
      title: l10n.evAuthorTitle(e.authorName ?? ''),
      subtitle: l10n.evAuthorSub(e.count),
      tag: l10n.evTagAuthor,
      icon: Icons.edit_note_rounded,
    ),
  };
}

/// Băng chuyền sự kiện ở đầu trang Khám phá. Không có sự kiện nào thì không chiếm chỗ.
class ExploreEvents extends ConsumerWidget {
  const ExploreEvents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(exploreEventsProvider).value;
    if (events == null || events.isEmpty) return const SizedBox.shrink();
    final compact = context.windowSize.isCompact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExploreHeader(
          icon: Icons.celebration_rounded,
          title: context.l10n.exploreEventsTitle,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) => SizedBox(
              width: compact ? 290 : 340,
              child: ExploreEventCard(event: events[i]),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class ExploreEventCard extends StatelessWidget {
  const ExploreEventCard({super.key, required this.event});

  final ExploreEvent event;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final text = context.textStyles;
    final t = exploreEventText(context, event);
    final covers = event.listings.take(1).toList();
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.go(Routes.exploreEvent(event.kind.name)),
      child: InfoPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.tintSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon, size: 14, color: c.tint),
                        const SizedBox(width: 4),
                        Text(
                          t.tag,
                          style: text.labelSmall?.copyWith(
                            color: c.tint,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: c.secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final l in covers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: BookPoster(
                        title: l.book.title,
                        author: l.book.author,
                        coverUrl: l.book.coverUrl,
                        seed: l.book.id,
                        width: 64,
                        shadow: false,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
