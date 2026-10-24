import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/clock.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Thông tin tối thiểu để vẽ một poster / nền mờ trong slide.
/// Đường dẫn tranh banner: `assets/banners/<id>.webp` (xem docs/BANNERS.md).
String _banner(String id) => 'assets/banners/$id.webp';

/// Nền thiết kế riêng cho slide sự kiện (không dùng ảnh bìa): bảng màu + biểu tượng lớn.
typedef _Theme = ({List<Color> colors, IconData icon});

typedef _Cover = ({String title, String author, String? url, String seed});

_Cover _coverOfBook(Book b) =>
    (title: b.title, author: b.author, url: b.coverUrl, seed: b.id);

/// Băng chuyền đầu trang Mua sách (kiểu Apple Books "Staff Picks / Featured collection"):
/// mỗi thẻ có dòng nhãn chữ hoa nhỏ, tiêu đề serif, và một thẻ ảnh nền là bìa sách phóng to + làm mờ
/// với khung kính chứa chữ. Không chỉ có sách: phiên đang live, gợi ý, ký gửi, mở shop…
/// Tự chuyển slide mỗi 7 giây, dừng khi người dùng đang kéo.
class HeroCarousel extends ConsumerStatefulWidget {
  const HeroCarousel({super.key, required this.feed});

  final HomeFeed feed;

  @override
  ConsumerState<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<HeroCarousel> {
  static const _interval = Duration(seconds: 7);

  PageController? _controller;
  double _fraction = 0;
  int _page = 0;
  Timer? _timer;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_interval, (_) => _advance());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _advance() {
    final c = _controller;
    if (!mounted || _dragging || c == null || !c.hasClients) return;
    _goTo(_page + 1);
  }

  void _goTo(int page, {int? count}) {
    final c = _controller;
    if (c == null || !c.hasClients) return;
    final n = count ?? _slideCount;
    c.animateToPage(
      (page % n + n) % n,
      duration: AppDurations.normal * 2,
      curve: Curves.easeOutCubic,
    );
  }

  int _slideCount = 1;

  List<Widget Function(BuildContext)> _slides(BuildContext context) {
    final l10n = context.l10n;
    final f = widget.feed;
    final picks = [for (final l in f.trending.take(3)) _coverOfBook(l.book)];
    final fresh = [for (final l in f.newArrivals.take(3)) _coverOfBook(l.book)];
    final spare = [
      for (final l in f.newArrivals.reversed.take(2)) _coverOfBook(l.book),
    ];
    return [
      for (final s in f.liveSessions.take(2))
        (c) => _LiveSlide(session: s, onOpen: () => c.go(Routes.live(s.id))),
      if (picks.isNotEmpty)
        (c) => _HeroCard(
          eyebrow: l10n.heroPicksEyebrow,
          headline: l10n.heroPicksHeadline,
          covers: picks,
          image: _banner('picks'),
          body: l10n.heroPicksBody,
          cta: l10n.heroPicksCta,
          onTap: () => c.go(Routes.search),
        ),
      (c) => _HeroCard(
        eyebrow: l10n.heroConsignEyebrow,
        headline: l10n.heroConsignHeadline,
        covers: spare,
        image: _banner('consign'),
        theme: (colors: HeroPalette.consign, icon: Icons.inventory_2_outlined),
        body: l10n.heroConsignBody,
        cta: l10n.heroConsignCta,
        onTap: () => c.go(Routes.newConsignment),
      ),
      if (fresh.isNotEmpty)
        (c) => _HeroCard(
          eyebrow: l10n.heroNewEyebrow,
          headline: l10n.heroNewHeadline,
          covers: fresh,
          image: _banner('new'),
          body: l10n.heroNewBody,
          cta: l10n.heroNewCta,
          onTap: () => c.go(Routes.search),
        ),
      (c) => _HeroCard(
        eyebrow: l10n.heroShopEyebrow,
        headline: l10n.heroShopHeadline,
        covers: picks.take(1).toList(),
        image: _banner('shop'),
        theme: (colors: HeroPalette.shop, icon: Icons.storefront_outlined),
        body: l10n.heroShopBody,
        cta: l10n.heroShopCta,
        onTap: () => c.go(Routes.openShop),
      ),
      if (spare.isNotEmpty)
        (c) => _HeroCard(
          eyebrow: l10n.heroRareEyebrow,
          headline: l10n.heroRareHeadline,
          covers: spare,
          image: _banner('rare'),
          body: l10n.heroRareBody,
          cta: l10n.heroRareCta,
          onTap: () => c.go(Routes.search),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.windowSize.isCompact;
    final slides = _slides(context);
    _slideCount = slides.length;
    final c = context.appColors;

    return LayoutBuilder(
      builder: (context, box) {
        // Thẻ rộng ~ 580px trên desktop (thấy 1,x thẻ như mockup), 88% màn hình trên điện thoại.
        final fraction = compact
            ? 0.92
            : (box.maxWidth <= 0 ? 1.0 : (600 / box.maxWidth).clamp(0.3, 1.0));
        if (_controller == null || (fraction - _fraction).abs() > 0.001) {
          final old = _controller;
          _controller = PageController(
            viewportFraction: fraction,
            initialPage: _page.clamp(0, slides.length - 1),
          );
          _fraction = fraction;
          if (old != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
          }
        }
        final height = compact ? 372.0 : 400.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height,
              child: Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollStartNotification &&
                          n.dragDetails != null) {
                        _dragging = true;
                      } else if (n is ScrollEndNotification) {
                        _dragging = false;
                      }
                      return false;
                    },
                    child: ScrollConfiguration(
                      // Cho phép kéo bằng chuột trên web.
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: PageView.builder(
                        controller: _controller,
                        padEnds: false,
                        itemCount: slides.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) => Padding(
                          padding: EdgeInsets.only(
                            left: compact ? 20 : 0,
                            right: AppSpacing.md,
                          ),
                          child: slides[i](context),
                        ),
                      ),
                    ),
                  ),
                  if (!compact) ...[
                    Positioned(
                      left: 10,
                      top: height / 2 - 20,
                      child: _Arrow(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => _goTo(_page - 1, count: slides.length),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: height / 2 - 20,
                      child: _Arrow(
                        icon: Icons.chevron_right_rounded,
                        onTap: () => _goTo(_page + 1, count: slides.length),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  GestureDetector(
                    onTap: () => _goTo(i, count: slides.length),
                    child: AnimatedContainer(
                      duration: AppDurations.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 20 : 7,
                      height: 7,
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(),
                        color: i == _page ? c.tint : c.tertiaryText,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 40,
    child: Glass.circle(
      onTap: onTap,
      child: Center(child: Icon(icon, size: 26)),
    ),
  );
}

/// Một thẻ: nhãn + tiêu đề serif phía trên, thẻ ảnh (nền bìa mờ + khung kính) phía dưới.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.eyebrow,
    required this.headline,
    required this.covers,
    this.body,
    this.cta,
    this.onTap,
    this.panel,
    this.theme,
    this.image,
  });

  /// Tranh banner do người dùng vẽ (`assets/banners/<tên>.webp`); thiếu file thì rơi về nền bên dưới.
  final String? image;

  /// Khác null → nền thiết kế (gradient + họa tiết); null → ảnh bìa phóng to làm nền.
  final _Theme? theme;

  final String eyebrow;
  final String headline;

  /// Bìa đầu tiên là nền mờ; tối đa 3 bìa xếp quạt bên phải.
  final List<_Cover> covers;
  final String? body;
  final String? cta;
  final VoidCallback? onTap;

  /// Thay cho [body] + [cta] (thẻ phiên live có giá / đồng hồ riêng).
  final Widget? panel;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final compact = context.windowSize.isCompact;
    final text = context.textStyles;
    final onDark = context.colors.onSurface;

    final content =
        panel ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (body != null)
              Text(
                body!,
                maxLines: compact ? 3 : 4,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(color: onDark),
              ),
            if (cta != null) ...[
              const SizedBox(height: AppSpacing.md),
              _BlackButton(label: cta!, onPressed: onTap),
            ],
          ],
        );

    // Chỉ hiện khi rê chuột vào thẻ: thẻ trắng mờ, chữ đen, nút đen.
    final glassPanel = DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.92),
        borderRadius: AppRadius.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: content,
      ),
    );

    return _HoverReveal(
      builder: (hover) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: text.labelSmall?.copyWith(
                color: c.secondaryText,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              headline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: (compact ? text.titleLarge : text.headlineSmall)?.copyWith(
                fontFamily: AppFonts.serif,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(26)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _backdrop(c, compact),
                    AnimatedOpacity(
                      opacity: hover ? 1 : 0,
                      duration: AppDurations.normal,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: compact
                                ? Alignment.bottomCenter
                                : Alignment.centerLeft,
                            end: compact
                                ? Alignment.topCenter
                                : Alignment.centerRight,
                            colors: HeroPalette.scrim,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(
                        compact ? AppSpacing.sm + 4 : AppSpacing.md,
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: compact ? 1000 : 340,
                          ),
                          child: AnimatedOpacity(
                            opacity: hover ? 1 : 0,
                            duration: AppDurations.normal,
                            child: IgnorePointer(
                              ignoring: !hover,
                              child: glassPanel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ảnh bìa phóng to phủ kín thẻ, hoặc nền gradient + họa tiết của slide sự kiện.
  /// Điện thoại dùng bản `<tên>-m.webp` (khung vuông); thiếu thì rơi về bản desktop, rồi về nền tạm.
  Widget _backdrop(AppColors c, bool compact) {
    final img = image;
    if (img != null) {
      final desktop = Image.asset(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackBackdrop(c),
      );
      if (!compact) return desktop;
      return Image.asset(
        img.replaceFirst('.webp', '-m.webp'),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => desktop,
      );
    }
    return _fallbackBackdrop(c);
  }

  Widget _fallbackBackdrop(AppColors c) {
    final t = theme;
    if (t != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: t.colors,
              ),
            ),
          ),
          const CustomPaint(painter: _RingsPainter(HeroPalette.ring)),
          Positioned(
            right: -24,
            top: -10,
            child: Icon(t.icon, size: 260, color: HeroPalette.glyph),
          ),
        ],
      );
    }
    if (covers.isEmpty) return ColoredBox(color: c.tint);
    final cv = covers.first;
    return FittedBox(
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.45),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 480,
        child: BookPoster(
          title: cv.title,
          author: cv.author,
          coverUrl: cv.url,
          seed: cv.seed,
          shadow: false,
        ),
      ),
    );
  }
}

/// Vòng tròn đồng tâm mờ ở góc phải — họa tiết nền cho slide sự kiện.
class _RingsPainter extends CustomPainter {
  const _RingsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;
    final center = Offset(size.width * 0.82, size.height * 0.3);
    for (var i = 1; i <= 7; i++) {
      canvas.drawCircle(center, i * 46.0, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}

/// Thẻ phiên đang diễn ra: lô hiện tại, giá, người đang dẫn, đồng hồ, nút vào phòng.
/// Làm mới mỗi 2 giây qua [liveStateProvider].
class _LiveSlide extends ConsumerWidget {
  const _LiveSlide({required this.session, required this.onOpen});

  final AuctionSession session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final onDark = context.colors.onSurface;
    final state = ref.watch(liveStateProvider(session.id)).value;
    final lot = state?.currentLot;

    final cover = lot != null
        ? _coverOfBook(lot.book)
        : (
            title: session.title,
            author: l10n.lotsCount(session.lotCount),
            url: session.coverImageUrl,
            seed: session.id,
          );

    Widget panel;
    if (state == null || lot == null) {
      panel = Text(
        l10n.waitingNextLot,
        style: text.bodyMedium?.copyWith(color: onDark),
      );
    } else {
      final offset = state.serverTime.difference(DateTime.now());
      final now = (ref.watch(clockProvider).value ?? DateTime.now()).add(
        offset,
      );
      final left = lot.endsAt?.difference(now);
      panel = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillBadge(l10n.live, color: c.live),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.viewers(state.viewerCount),
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: onDark.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatVnd(lot.currentPrice),
            style: text.headlineSmall?.copyWith(color: onDark),
          ),
          Text(
            [
              if (lot.leadingPaddle != null)
                l10n.leadingPaddle(lot.leadingPaddle!),
              if (left != null)
                l10n.timeLeft(
                  formatCountdown(left.isNegative ? Duration.zero : left),
                ),
            ].join(' · '),
            style: text.bodySmall?.copyWith(
              color: onDark.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _BlackButton(label: l10n.enterLiveRoom, onPressed: onOpen),
        ],
      );
    }

    return _HeroCard(
      eyebrow: l10n.heroLiveEyebrow,
      headline: lot?.book.title ?? session.title,
      covers: [cover],
      image: _banner('live'),
      panel: panel,
      onTap: onOpen,
    );
  }
}

/// Theo dõi chuột đang nằm trên thẻ hay không (điện thoại không có chuột → luôn false, chạm để mở).
class _HoverReveal extends StatefulWidget {
  const _HoverReveal({required this.builder});

  final Widget Function(bool hover) builder;

  @override
  State<_HoverReveal> createState() => _HoverRevealState();
}

class _HoverRevealState extends State<_HoverReveal> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: widget.builder(_hover),
  );
}

/// Nút đen (chữ trắng ở sáng, ngược lại ở tối) dùng trong thẻ banner.
class _BlackButton extends StatelessWidget {
  const _BlackButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: context.colors.onSurface,
      foregroundColor: context.colors.surface,
    ),
    child: Text(label),
  );
}
