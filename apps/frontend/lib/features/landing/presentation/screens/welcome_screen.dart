import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/landing/presentation/widgets/scenes_a.dart';
import 'package:book_marketplace/features/landing/presentation/widgets/scenes_b.dart';
import 'package:book_marketplace/features/landing/presentation/widgets/scenes_c.dart';
import 'package:book_marketplace/features/landing/presentation/widgets/welcome_kit.dart';

/// Trang giới thiệu (web `/`): dựng lại video tham chiếu — một trang cuộn dài gồm 9 cảnh,
/// animation chạy theo thời gian (đoạn mở đầu của hero) và theo tiến độ cuộn (các cảnh được ghim).
/// Tham số `?y=<px>` mở trang ở vị trí cuộn cho trước (dùng để chụp ảnh kiểm tra).
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.initialOffset = 0});

  final double initialOffset;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.initialOffset,
  );

  /// Đoạn mở đầu của hero: 0..1 trong ~4 giây (chạy một lần).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..forward(from: widget.initialOffset > 0 ? 1 : 0);

  /// Đồng hồ chạy mãi (băng chuyền, doodle nổi): value × 3600 = giây.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(hours: 1),
  )..repeat();

  @override
  void dispose() {
    _scroll.dispose();
    _intro.dispose();
    _clock.dispose();
    super.dispose();
  }

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Nạp sẵn mọi bìa để các thẻ không nháy trắng khi hiện ra.
    if (!_precached) {
      _precached = true;
      for (final a in kLandingCovers) {
        precacheImage(AssetImage(a), context);
      }
    }
  }

  void _go(String path) => context.go(path);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final vh = size.height;
    final compact = size.width < 700;

    // (chiều cao, ghim?, vẽ cảnh, animation phụ)
    final defs =
        <
          (double, bool, Widget Function(BuildContext, ScrollInfo), Listenable?)
        >[
          (
            vh * 1.7,
            true,
            (c, i) => HeroScene(
              info: i,
              intro: _intro,
              onExplore: () => _go(Routes.home),
              onAuctions: () => _go(Routes.auctions),
            ),
            _intro,
          ),
          (
            vh * 1.6,
            true,
            (c, i) => ShowcaseScene(
              info: i,
              onStart: () => _go(Routes.home),
              onLearn: () => _go(Routes.auctions),
            ),
            null,
          ),
          (
            vh * 2.3,
            true,
            (c, i) => GatewayScene(info: i, onOpen: () => _go(Routes.home)),
            null,
          ),
          (
            vh * 3.6,
            true,
            (c, i) => StoryScene(info: i, clock: _clock),
            _clock,
          ),
          (vh * 1.9, true, (c, i) => AmongScene(info: i), null),
          (vh * 2.5, true, (c, i) => FeaturesScene(info: i), null),
          (
            vh * 2.8,
            true,
            (c, i) => MarketScene(info: i, onJoin: () => _go(Routes.home)),
            null,
          ),
          (
            vh * 1.7,
            true,
            (c, i) => PricingScene(info: i, clock: _clock),
            _clock,
          ),
          (
            OutroScene.heightFor(vh, compact),
            false,
            (c, i) => OutroScene(
              info: i,
              clock: _clock,
              onJoin: () => _go(Routes.home),
              onAuctions: () => _go(Routes.auctions),
              onEnter: () => _go(Routes.home),
              onExplore: () => _go(Routes.home),
              onConsign: () => _go(Routes.newConsignment),
              onLogin: () => _go(Routes.login),
            ),
            _clock,
          ),
        ];

    var start = 0.0;
    final scenes = <Widget>[];
    for (final d in defs) {
      scenes.add(
        WelcomeScene(
          controller: _scroll,
          start: start,
          height: d.$1,
          pinned: d.$2,
          extra: d.$4,
          builder: d.$3,
        ),
      );
      start += d.$1;
    }

    return Scaffold(
      backgroundColor: LandingPalette.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(children: scenes),
          ),
          _WelcomeNav(
            scroll: _scroll,
            intro: _intro,
            onEnter: () => _go(Routes.home),
            onLogin: () => _go(Routes.login),
            onDiscover: () => _go(Routes.home),
            onAuctions: () => _go(Routes.auctions),
            onConsign: () => _go(Routes.newConsignment),
          ),
        ],
      ),
    );
  }
}

/// Thanh điều hướng: đầy đủ ở đầu trang, sau khi hero thu lại thì gọn thành viên thuốc đen ở giữa (video 4 s).
class _WelcomeNav extends StatelessWidget {
  const _WelcomeNav({
    required this.scroll,
    required this.intro,
    required this.onEnter,
    required this.onLogin,
    required this.onDiscover,
    required this.onAuctions,
    required this.onConsign,
  });

  final ScrollController scroll;
  final Animation<double> intro;
  final VoidCallback onEnter;
  final VoidCallback onLogin;
  final VoidCallback onDiscover;
  final VoidCallback onAuctions;
  final VoidCallback onConsign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 700;
    return AnimatedBuilder(
      animation: Listenable.merge([scroll, intro]),
      builder: (context, _) {
        final off = scroll.hasClients
            ? scroll.offset
            : scroll.initialScrollOffset;
        final m = seg(off, size.height * 0.5, size.height * 0.9);
        final fade = seg(intro.value, 0.55, 0.8);
        Widget link(String t, VoidCallback f) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: f,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(t, style: landingText(13, weight: FontWeight.w500)),
            ),
          ),
        );
        return Stack(
          children: [
            Positioned(
              top: 18,
              left: 28,
              right: 28,
              child: IgnorePointer(
                ignoring: m > 0.5,
                child: Opacity(
                  opacity: fade * (1 - m),
                  child: Row(
                    children: [
                      Text(
                        l10n.appTitle,
                        style: landingText(
                          20,
                          weight: FontWeight.w700,
                          spacing: -0.6,
                        ),
                      ),
                      const Spacer(),
                      if (!compact) ...[
                        link(l10n.wlNavDiscover, onDiscover),
                        link(l10n.navAuctions, onAuctions),
                        link(l10n.consignTitle, onConsign),
                        const Spacer(),
                      ],
                      link(l10n.login, onLogin),
                      const SizedBox(width: 6),
                      LandingButton(l10n.wlEnter, onTap: onEnter, size: 13),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: m < 0.5,
                child: Center(
                  child: Opacity(
                    opacity: m,
                    child: Transform.translate(
                      offset: Offset(0, (1 - m) * -20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: LandingPalette.ink,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: onEnter,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                child: Text(
                                  l10n.wlEnter,
                                  style: landingText(
                                    13,
                                    color: LandingPalette.white,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: onLogin,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                child: Text(
                                  l10n.login,
                                  style: landingText(
                                    13,
                                    color: LandingPalette.white54,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
