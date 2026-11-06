import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/app/theme/soft_palette.dart';
import 'package:book_marketplace/core/settings/intro_state.dart';
import 'package:book_marketplace/shared/widgets/skeleton.dart';

/// Màn mở app. Điện thoại: splash thương hiệu (nền trắng, tên app to, dòng phụ có chữ nhấn) giữ chừng
/// một giây rưỡi. Web: khung xương của trang chủ nhấp nháy trong lúc đọc phiên đăng nhập.
/// Router tự chuyển đi khi xong.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _timer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) ref.read(splashHoldProvider.notifier).release();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      kIsWeb ? const _SkeletonSplash() : const _BrandSplash();
}

class _BrandSplash extends StatelessWidget {
  const _BrandSplash();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    return Scaffold(
      backgroundColor: SoftPalette.paper,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - t)),
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 22,
                child: CustomPaint(painter: _OpenBook()),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.appTitle,
                style: text.displayLarge?.copyWith(
                  color: SoftPalette.ink,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  text: '${l10n.splashTaglineLead} ',
                  children: [
                    TextSpan(
                      text: l10n.splashTaglineAccent,
                      style: const TextStyle(color: SoftPalette.brick),
                    ),
                  ],
                ),
                style: text.bodyMedium?.copyWith(color: SoftPalette.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quyển sách mở nhỏ phía trên chữ, thay cho vòng hào quang trong mẫu.
class _OpenBook extends CustomPainter {
  const _OpenBook();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = SoftPalette.brick
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, h * 0.28)
      ..quadraticBezierTo(w * 0.28, 0, 0, h * 0.14)
      ..lineTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.28, h * 0.72, w / 2, h)
      ..quadraticBezierTo(w * 0.72, h * 0.72, w, h * 0.86)
      ..lineTo(w, h * 0.14)
      ..quadraticBezierTo(w * 0.72, 0, w / 2, h * 0.28)
      ..moveTo(w / 2, h * 0.28)
      ..lineTo(w / 2, h);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_OpenBook old) => false;
}

/// Màn loading của web: khung xương của trang chủ (tiêu đề, ô tìm, chip, thẻ lớn, danh sách).
class _SkeletonSplash extends StatelessWidget {
  const _SkeletonSplash();

  @override
  Widget build(BuildContext context) {
    const chips = [72.0, 56.0, 98.0, 82.0, 64.0];
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ClipRect(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(width: 96, height: 10),
                              SizedBox(height: 10),
                              Skeleton(width: 220, height: 14),
                              SizedBox(height: 8),
                              Skeleton(width: 150, height: 14),
                            ],
                          ),
                        ),
                        Skeleton(height: 44, circle: true),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Row(
                      children: [
                        Expanded(child: Skeleton(height: 52, radius: 18)),
                        SizedBox(width: AppSpacing.sm),
                        Skeleton(width: 52, height: 52, radius: 16),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final w in chips)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Skeleton(width: w, height: 38, radius: 19),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionBar(),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 210,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          _BigCard(width: 250),
                          SizedBox(width: AppSpacing.md),
                          _BigCard(width: 250),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionBar(),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < 3; i++) const _Row(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBar extends StatelessWidget {
  const _SectionBar();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Skeleton(width: 110, height: 12),
      Skeleton(width: 48, height: 10),
    ],
  );
}

class _BigCard extends StatelessWidget {
  const _BigCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Stack(
      children: [
        const Positioned.fill(child: Skeleton(height: 210, radius: 24)),
        Positioned(
          left: 16,
          right: 48,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(height: 10, radius: 5, width: width * 0.62),
              const SizedBox(height: 8),
              Skeleton(height: 8, radius: 4, width: width * 0.4),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: AppSpacing.md),
    child: Row(
      children: [
        Skeleton(width: 64, height: 64, radius: 14),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 150, height: 10),
              SizedBox(height: 8),
              Skeleton(height: 10),
              SizedBox(height: 8),
              Skeleton(width: 90, height: 10),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Skeleton(width: 4, height: 18, radius: 2),
      ],
    ),
  );
}
