import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/app/theme/soft_art.dart';
import 'package:book_marketplace/app/theme/soft_palette.dart';
import 'package:book_marketplace/core/settings/intro_state.dart';

/// Giới thiệu 3 trang (vuốt ngang) lúc mở app lần đầu trên điện thoại. Mỗi trang một màu nền phẳng, một
/// tranh minh hoạ mềm, tiêu đề ngắn, chấm trang, nút "Đăng ký miễn phí" và dòng "Hoặc đăng nhập".
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  static const _backgrounds = [
    SoftPalette.peach,
    SoftPalette.blush,
    SoftPalette.brick,
  ];
  static const _arts = [
    SoftArtKind.books,
    SoftArtKind.auction,
    SoftArtKind.box,
  ];

  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _leaveTo(String route) async {
    await ref.read(introSeenProvider.notifier).markSeen();
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titles = [l10n.obTitle1, l10n.obTitle2, l10n.obTitle3];
    final bodies = [l10n.obBody1, l10n.obBody2, l10n.obBody3];
    return Scaffold(
      backgroundColor: _backgrounds[_index],
      body: PageView.builder(
        controller: _pages,
        itemCount: _backgrounds.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => _IntroPage(
          background: _backgrounds[i],
          art: _arts[i],
          title: titles[i],
          body: bodies[i],
          index: i,
          count: _backgrounds.length,
          onSignUp: () => _leaveTo(Routes.register),
          onLogin: () => _leaveTo(Routes.login),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.background,
    required this.art,
    required this.title,
    required this.body,
    required this.index,
    required this.count,
    required this.onSignUp,
    required this.onLogin,
  });

  final Color background;
  final SoftArtKind art;
  final String title;
  final String body;
  final int index;
  final int count;
  final VoidCallback onSignUp;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    return ColoredBox(
      color: background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: Center(
                      child: LayoutBuilder(
                        builder: (_, box) => SoftArt(
                          art,
                          size: box.biggest.shortestSide.clamp(200, 400),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(
                      color: SoftPalette.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: SoftPalette.ink.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < count; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == index
                                ? SoftPalette.ink
                                : SoftPalette.paper.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: onSignUp,
                      style: FilledButton.styleFrom(
                        backgroundColor: SoftPalette.ink,
                        foregroundColor: SoftPalette.cream,
                        shape: const StadiumBorder(),
                        textStyle: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(l10n.obSignUpFree),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: onLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: SoftPalette.ink,
                      minimumSize: const Size(0, 48),
                      textStyle: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.obOrLogIn),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
