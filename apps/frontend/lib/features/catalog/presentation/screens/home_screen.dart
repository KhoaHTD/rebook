import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/mode_switch.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/category_shelves.dart';
import 'package:book_marketplace/features/catalog/presentation/widgets/hero_carousel.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/cover_flow_home.dart';
import 'package:book_marketplace/shared/widgets/skeleton.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Trang "Mua sách": mỗi nhóm thể loại có sách là một kệ (10 cuốn phổ biến nhất + một "cuốn sách giả" dẫn tới Khám phá
/// để xem hết). Điện thoại là [CoverFlowHome] (nền màu theo bìa, hàng bìa lớn là 5 cuốn phổ biến nhất sàn, thanh tab
/// thể loại cuộn tới kệ); desktop là băng chuyền + [CategoryShelvesDesktop]. Phần đấu giá nằm ở khu riêng (nút đổi khu).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(sessionControllerProvider).user;
    final feed = ref.watch(homeFeedProvider);
    final shelves = ref.watch(categoryShelvesProvider);
    if (context.windowSize.isCompact) return const _MobileHome();

    return AppPage(
      title: user == null
          ? l10n.homeGreetingGuest
          : l10n.homeGreeting(user.fullName.split(' ').last),
      subtitle: l10n.homeTagline,
      onRefresh: () async {
        ref.invalidate(categoryShelvesProvider);
        ref.invalidate(homeFeedProvider);
        await ref.read(homeFeedProvider.future);
      },
      children: [
        AsyncValueView(
          value: feed,
          onRetry: () => ref.invalidate(homeFeedProvider),
          loading: const SkeletonHome(),
          data: (f) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: HeroCarousel(feed: f),
          ),
        ),
        AsyncValueView(
          value: shelves,
          onRetry: () => ref.invalidate(categoryShelvesProvider),
          loading: const SizedBox.shrink(),
          data: (list) => list.isEmpty
              ? Text(l10n.homeShelfEmpty)
              : CategoryShelvesDesktop(shelves: list),
        ),
      ],
    );
  }
}

void _openListing(BuildContext context, String id) =>
    context.go(Routes.listing(id));

/// Điện thoại: dữ liệu thật cho [CoverFlowHome]. Hàng bìa lớn là 5 cuốn phổ biến nhất sàn; thanh tab là "Tất cả" rồi từng
/// nhóm thể loại có sách, bấm tab thì cuộn tới kệ đó. Mỗi kệ có tối đa 10 cuốn phổ biến nhất và "cuốn sách giả" cuối kệ.
class _MobileHome extends ConsumerWidget {
  const _MobileHome();

  CoverFlowEntry _entry(BuildContext context, Listing l) => CoverFlowEntry(
    id: l.id,
    title: l.book.title,
    author: l.book.author,
    coverUrl: l.book.coverUrl,
    price: formatVnd(l.price),
    onTap: () => _openListing(context, l.id),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final feed = ref.watch(homeFeedProvider);
    final shelves = ref.watch(categoryShelvesProvider);

    Widget retry() => Center(
      child: TextButton(
        onPressed: () {
          ref.invalidate(homeFeedProvider);
          ref.invalidate(categoryShelvesProvider);
        },
        child: Text(l10n.retry),
      ),
    );
    const skeleton = SafeArea(
      child: SkeletonHome(padding: EdgeInsets.all(AppSpacing.lg)),
    );

    return feed.when(
      skipLoadingOnReload: true,
      loading: () => skeleton,
      error: (_, _) => retry(),
      data: (f) => shelves.when(
        skipLoadingOnReload: true,
        loading: () => skeleton,
        error: (_, _) => retry(),
        data: (List<CategoryShelf> list) {
          final heroSource = f.trending.isNotEmpty ? f.trending : f.newArrivals;
          return CoverFlowHome(
            title: l10n.homeExploreTitle,
            trailing: (onHero) =>
                ModeButton(mode: AppMode.books, onHero: onHero),
            hero: [for (final l in heroSource.take(5)) _entry(context, l)],
            tabs: [l10n.allCategories, for (final s in list) s.category.name],
            shelves: [
              for (final s in list)
                CoverFlowShelf(
                  s.category.name,
                  [for (final l in s.items.take(10)) _entry(context, l)],
                  onSeeAll: () =>
                      context.go(Routes.searchCategory(s.category.id)),
                  seeAllLabel: l10n.seeAll,
                  seeAllCaption: l10n.seeAllCount(s.total),
                ),
            ],
            emptyText: l10n.homeShelfEmpty,
          );
        },
      ),
    );
  }
}
