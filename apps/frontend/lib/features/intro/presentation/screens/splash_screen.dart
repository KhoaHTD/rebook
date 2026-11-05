import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/skeleton.dart';

/// Màn loading lúc mở app: khung xương của trang chủ (tiêu đề, ô tìm, chip, thẻ lớn, danh sách) nhấp nháy
/// trong lúc app đọc phiên đăng nhập. Router tự chuyển đi khi xong.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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
