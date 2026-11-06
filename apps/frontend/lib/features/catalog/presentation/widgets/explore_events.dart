import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/catalog/domain/explore_event.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/cover_color.dart';

/// Tiêu đề, mô tả ngắn, biểu tượng và nhãn của từng bộ sưu tập (dùng cho thẻ và trang bộ sưu tập).
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
    ExploreEventKind.top => ExploreEventText(
      title: l10n.evTopTitle,
      subtitle: l10n.evTopSub,
      tag: l10n.evTopTag,
      icon: Icons.emoji_events_rounded,
    ),
    ExploreEventKind.forYou => ExploreEventText(
      title: l10n.evForYouTitle,
      subtitle: l10n.evForYouSub(e.count),
      tag: l10n.evForYouTag,
      icon: Icons.favorite_rounded,
    ),
    ExploreEventKind.newRelease => ExploreEventText(
      title: l10n.evNewTitle,
      subtitle: l10n.evNewSub(e.count, newReleaseFromYear),
      tag: l10n.evNewTag,
      icon: Icons.new_releases_rounded,
    ),
    ExploreEventKind.cheap => ExploreEventText(
      title: l10n.evCheapTitle(formatVnd(cheapEventMaxPrice)),
      subtitle: l10n.evCheapSub(e.count, formatVnd(e.minPrice)),
      tag: l10n.evTagDeal,
      icon: Icons.sell_rounded,
    ),
    ExploreEventKind.likeNew => ExploreEventText(
      title: l10n.evLikeNewTitle,
      subtitle: l10n.evLikeNewSub(e.count),
      tag: l10n.evTagLikeNew,
      icon: Icons.auto_awesome_rounded,
    ),
    ExploreEventKind.classics => ExploreEventText(
      title: l10n.evClassicsTitle,
      subtitle: l10n.evClassicsSub(e.count),
      tag: l10n.evClassicsTag,
      icon: Icons.menu_book_rounded,
    ),
    ExploreEventKind.theme => switch (e.theme!) {
      ExploreTheme.humor => ExploreEventText(
        title: l10n.evThemeHumor,
        subtitle: l10n.evThemeSub(e.count),
        tag: l10n.evThemeTag,
        icon: Icons.sentiment_very_satisfied_rounded,
      ),
      ExploreTheme.memoir => ExploreEventText(
        title: l10n.evThemeMemoir,
        subtitle: l10n.evThemeSub(e.count),
        tag: l10n.evThemeTag,
        icon: Icons.history_edu_rounded,
      ),
      ExploreTheme.gothic => ExploreEventText(
        title: l10n.evThemeGothic,
        subtitle: l10n.evThemeSub(e.count),
        tag: l10n.evThemeTag,
        icon: Icons.nightlight_round,
      ),
      ExploreTheme.food => ExploreEventText(
        title: l10n.evThemeFood,
        subtitle: l10n.evThemeSub(e.count),
        tag: l10n.evThemeTag,
        icon: Icons.restaurant_rounded,
      ),
      ExploreTheme.selfHelp => ExploreEventText(
        title: l10n.evThemeSelfHelp,
        subtitle: l10n.evThemeSub(e.count),
        tag: l10n.evThemeTag,
        icon: Icons.self_improvement_rounded,
      ),
    },
    ExploreEventKind.quickRead => ExploreEventText(
      title: l10n.evQuickTitle,
      subtitle: l10n.evQuickSub(e.count, quickReadMaxPages),
      tag: l10n.evQuickTag,
      icon: Icons.bolt_rounded,
    ),
    ExploreEventKind.thick => ExploreEventText(
      title: l10n.evThickTitle,
      subtitle: l10n.evThickSub(e.count, thickMinPages),
      tag: l10n.evThickTag,
      icon: Icons.auto_stories_rounded,
    ),
    ExploreEventKind.author => ExploreEventText(
      title: l10n.evAuthorTitle(e.subject ?? ''),
      subtitle: l10n.evAuthorSub(e.count),
      tag: l10n.evTagAuthor,
      icon: Icons.edit_note_rounded,
    ),
    ExploreEventKind.publisher => ExploreEventText(
      title: l10n.evPublisherTitle(e.subject ?? ''),
      subtitle: l10n.evPublisherSub(e.count),
      tag: l10n.evPublisherTag,
      icon: Icons.apartment_rounded,
    ),
  };
}

/// Màu nền của một bộ sưu tập: cố định theo khoá của bộ, lấy từ bảng màu bìa.
Color exploreEventColor(ExploreEvent e) => CoverColor.fallback(e.key);

/// Gradient nền thẻ bộ sưu tập (đậm dần xuống dưới).
LinearGradient exploreEventGradient(Color base) {
  final hsl = HSLColor.fromColor(base);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      base,
      hsl.withLightness((hsl.lightness - 0.12).clamp(0.05, 1.0)).toColor(),
    ],
  );
}

/// Kiểu thẻ bộ sưu tập: [hero] banner lớn, [tall] ô cao (hai bìa), [short] ô thấp (một bìa).
enum EventCardStyle { hero, tall, short }

/// Thẻ một bộ sưu tập: nền màu, nhãn, tên, mô tả và các bìa xếp chồng; bấm để mở trang bộ sưu tập.
class ExploreEventCard extends StatelessWidget {
  const ExploreEventCard({
    super.key,
    required this.event,
    this.style = EventCardStyle.short,
    this.height,
    this.tappable = true,
  });

  final ExploreEvent event;
  final EventCardStyle style;
  final double? height;

  /// Bấm thẻ thì mở trang bộ sưu tập (tắt ở chính trang bộ sưu tập).
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final t = exploreEventText(context, event);
    final text = context.textStyles;
    final base = exploreEventColor(event);
    final books = event.listings.take(3).toList();
    const onColor = CoverPalette.onHero;
    final hero = style == EventCardStyle.hero;
    // Banner thấp (điện thoại): chữ nhỏ hơn để vừa khung.
    final small = hero && (height ?? 999) < 280;
    final tall = style == EventCardStyle.tall;

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: onColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(t.icon, size: 14, color: onColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              t.tag,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    final titleText = Text(
      t.title,
      maxLines: hero ? (small ? 2 : 3) : (tall ? 3 : 2),
      overflow: TextOverflow.ellipsis,
      style:
          (hero
                  ? (small ? text.headlineSmall : text.headlineMedium)
                  : text.titleMedium)
              ?.copyWith(
                color: onColor,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
    );
    final sub = Text(
      t.subtitle,
      maxLines: hero ? (small ? 2 : 3) : 2,
      overflow: TextOverflow.ellipsis,
      style: text.bodySmall?.copyWith(color: onColor.withValues(alpha: 0.82)),
    );

    Widget body;
    if (hero) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                pill,
                const SizedBox(height: AppSpacing.md),
                titleText,
                const SizedBox(height: 6),
                sub,
                const Spacer(),
                if (tappable)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: onColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            context.l10n.exploreViewCollection,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelLarge?.copyWith(
                              color: base,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: base,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(flex: 4, child: ExploreCoverFan(books: books, big: true)),
        ],
      );
    } else if (tall) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          pill,
          const SizedBox(height: AppSpacing.sm),
          titleText,
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              height: 78,
              child: ExploreCoverFan(books: books.take(2).toList(), big: false),
            ),
          ),
        ],
      );
    } else {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [pill, const SizedBox(height: 6), titleText],
            ),
          ),
          if (books.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: BookPoster(
                title: books.first.book.title,
                author: books.first.book.author,
                coverUrl: books.first.book.coverUrl,
                seed: books.first.book.id,
                width: 46,
                shadow: false,
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: tappable ? () => context.go(Routes.exploreEvent(event.key)) : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: height,
          padding: EdgeInsets.all(hero ? AppSpacing.lg : AppSpacing.md),
          decoration: BoxDecoration(
            gradient: exploreEventGradient(base),
            borderRadius: BorderRadius.circular(hero ? 28 : 22),
          ),
          child: body,
        ),
      ),
    );
  }
}

/// Các bìa xếp chồng của một bộ sưu tập (dùng cả ở thẻ tác giả / nhà xuất bản).
class ExploreCoverFan extends StatelessWidget {
  const ExploreCoverFan({super.key, required this.books, required this.big});

  final List<Listing> books;
  final bool big;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, box) {
        final w = big ? math.min(box.maxWidth * 0.52, 120.0) : 46.0;
        final shift = big ? box.maxWidth * 0.22 : 24.0;
        // Vẽ từ cuốn cuối đến cuốn đầu để cuốn đầu nằm trên cùng.
        final order = [for (var i = books.length - 1; i >= 0; i--) i];
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            for (final i in order)
              Transform.translate(
                offset: Offset(
                  (i - (books.length - 1) / 2) * shift,
                  big ? i * 4.0 : 0,
                ),
                child: Transform.rotate(
                  angle: (i - (books.length - 1) / 2) * 0.12,
                  child: BookPoster(
                    title: books[i].book.title,
                    author: books[i].book.author,
                    coverUrl: books[i].book.coverUrl,
                    seed: books[i].book.id,
                    width: w,
                    shadow: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
