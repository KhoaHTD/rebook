import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/settings/intro_state.dart';

/// Giới thiệu 3 trang (vuốt ngang) lúc mở app lần đầu: tranh ở nửa trên có mép dưới rách như giấy xé,
/// nửa dưới là tiêu đề, mô tả, chấm trang và nút Bỏ qua / Tiếp.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  static const _art = [
    'assets/banners/picks.jpg',
    'assets/banners/shop.jpg',
    'assets/banners/live.jpg',
  ];

  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(introSeenProvider.notifier).markSeen();
    if (mounted) context.go(Routes.home);
  }

  void _next() {
    if (_index == _art.length - 1) {
      _finish();
    } else {
      _pages.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final titles = [l10n.introTitle1, l10n.introTitle2, l10n.introTitle3];
    final bodies = [l10n.introBody1, l10n.introBody2, l10n.introBody3];
    final last = _index == _art.length - 1;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _art.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => _IntroPage(
                      art: _art[i],
                      title: titles[i],
                      body: bodies[i],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < _art.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.only(right: 6),
                              width: i == _index ? 22 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _index ? c.tint : c.fill,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _finish,
                            child: Text(l10n.introSkip),
                          ),
                          FilledButton(
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(128, 48),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              last ? l10n.introStart : l10n.introNext,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.art,
    required this.title,
    required this.body,
  });

  final String art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final text = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 7,
          child: ClipPath(
            clipper: const _TornEdge(),
            child: ColoredBox(
              color: c.tintSoft,
              child: Image.asset(
                art,
                fit: BoxFit.cover,
                alignment: const Alignment(0.8, 0.2),
                // Tranh nền trắng: nhân với màu nhạt của app để liền với nền trang.
                color: c.tintSoft,
                colorBlendMode: BlendMode.multiply,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, AppSpacing.lg, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  body,
                  style: text.bodyLarge?.copyWith(color: c.secondaryText),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Mép dưới rách như giấy xé: các răng cưa cao thấp không đều nhưng cố định (không nhấp nháy khi dựng lại).
class _TornEdge extends CustomClipper<Path> {
  const _TornEdge();

  static const _depth = 16.0;
  static const _step = 9.0;

  @override
  Path getClip(Size size) {
    final base = size.height - _depth;
    final path = Path()..lineTo(0, base);
    var x = 0.0;
    var i = 0;
    while (x < size.width) {
      x = math.min(x + _step, size.width);
      path.lineTo(x, base + _depth * (((i * 37) % 11) / 11));
      i++;
    }
    return path
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_TornEdge old) => false;
}
