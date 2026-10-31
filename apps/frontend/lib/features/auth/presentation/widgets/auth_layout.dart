import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Vài cuốn kinh điển trên tấm giới thiệu: dùng đúng ảnh bìa như trang chủ (ảnh đóng gói trong `assets/books/`),
/// nên chiều cao mỗi cuốn theo tỉ lệ bìa thật và canh đáy.
const _heroBooks = [
  ('Số đỏ', 'Vũ Trọng Phụng', 'assets/books/so-do-0.jpg'),
  ('Truyện Kiều', 'Nguyễn Du', 'assets/books/truyen-kieu-0.jpg'),
  ('Tắt đèn', 'Ngô Tất Tố', 'assets/books/tat-den-0.jpg'),
  ('Vang bóng một thời', 'Nguyễn Tuân', 'assets/books/vang-bong-0.jpg'),
];

/// Khung các màn đăng nhập / đăng ký / OTP / quên mật khẩu.
/// Desktop: tấm giới thiệu xám nhạt có poster sách bên trái, form bên phải. Mobile: chỉ form.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final compact = context.windowSize.isCompact;
    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBack)
                Align(
                  alignment: Alignment.centerLeft,
                  child: CircleBackButton(
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(Routes.home),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: context.textStyles.displaySmall),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.appColors.secondaryText,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              ...children,
              if (Env.useMock) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.mockAccountsHint,
                  style: context.textStyles.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: compact
            ? form
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: _Hero()),
                  Expanded(child: form),
                ],
              ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: context.appColors.sidebar,
        borderRadius: AppRadius.sidebar,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.appTitle,
            style: context.textStyles.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          LayoutBuilder(
            builder: (context, box) {
              // Bề rộng mỗi cuốn co theo tấm giới thiệu (tối đa 104), một hàng, canh đáy.
              final w =
                  ((box.maxWidth - AppSpacing.md * (_heroBooks.length - 1)) /
                          _heroBooks.length)
                      .clamp(48.0, 104.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, b) in _heroBooks.indexed) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    BookPoster(
                      title: b.$1,
                      author: b.$2,
                      coverUrl: b.$3,
                      seed: 'hero-$i',
                      width: w,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            '${l10n.authHeroTitle} ${l10n.authHeroAccent}',
            style: context.textStyles.displaySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              l10n.authHeroBody,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.appColors.secondaryText,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Dòng "Chưa có tài khoản? Đăng ký" ở cuối form.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.appColors.secondaryText,
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}

/// Lỗi của lần gửi form gần nhất (dưới các ô nhập).
class AuthError extends StatelessWidget {
  const AuthError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    child: Text(
      message,
      style: context.textStyles.bodyMedium?.copyWith(
        color: context.appColors.live,
      ),
    ),
  );
}
