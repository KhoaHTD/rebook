import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/app/theme/soft_palette.dart';
import 'package:book_marketplace/features/auth/presentation/providers/auth_controller.dart';

/// Khung các màn đăng nhập / đăng ký / OTP / quên mật khẩu, dùng chung điện thoại và web: nền trắng với vòng tròn xanh nhạt,
/// ô nhập gạch chân, nút đen bo tròn. Màn rộng (web / máy tính bảng) đặt form trong một thẻ trắng nổi ở giữa nền xanh nhạt.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.showBack = true,
    this.showGoogle = false,
    this.onSkip,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showBack;

  /// Hiện nút "Tiếp tục với Google" và dòng "Hoặc dùng email".
  final bool showGoogle;

  /// Có nút "Bỏ qua" ở góc trên để vào trang chủ bằng tài khoản khách.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) => _softBuild(context);
}

extension on AuthLayout {
  /// Bản điện thoại: nền kem, nút đen bo tròn, ô nhập gạch chân, nút Google và "Bỏ qua" (theo mẫu đã duyệt).
  Widget _softBuild(BuildContext context) {
    final l10n = context.l10n;
    final base = Theme.of(context);
    const ink = SoftPalette.night;
    const line = UnderlineInputBorder(
      borderSide: BorderSide(color: SoftPalette.underline),
    );
    final theme = base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: SoftPalette.cream,
          disabledBackgroundColor: ink.withValues(alpha: 0.25),
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: ink),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: false,
        border: line,
        enabledBorder: line,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ink, width: 1.6),
        ),
      ),
    );

    final wide = MediaQuery.sizeOf(context).width >= 700;
    Widget framed(Widget content) => wide
        ? Container(
            padding: const EdgeInsets.fromLTRB(36, 20, 36, 36),
            decoration: BoxDecoration(
              color: SoftPalette.paper,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: SoftPalette.night.withValues(alpha: 0.07),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: content,
          )
        : content;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: wide ? SoftPalette.mist : SoftPalette.paper,
        body: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: _Blob(260, wide ? SoftPalette.sky : SoftPalette.mist),
            ),
            if (wide)
              const Positioned(
                bottom: -120,
                left: -80,
                child: _Blob(320, SoftPalette.sky),
              ),
            SafeArea(
              child: Align(
                alignment: wide ? Alignment.center : Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    wide ? AppSpacing.lg : AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: framed(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (showBack)
                                IconButton(
                                  tooltip: l10n.back,
                                  onPressed: () => context.canPop()
                                      ? context.pop()
                                      : context.go(Routes.home),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                )
                              else
                                const SizedBox(height: 48),
                              if (onSkip != null)
                                TextButton(
                                  onPressed: onSkip,
                                  child: Text(l10n.introSkip),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            title,
                            style: context.textStyles.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              subtitle!,
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: ink.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          if (showGoogle) ...[
                            const _GoogleButton(),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.authOrEmail,
                              style: context.textStyles.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          ...children,
                          if (Env.useMock) ...[
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              l10n.mockAccountsHint,
                              style: context.textStyles.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Tiếp tục với Google": mở trang đăng nhập Google ở trình duyệt; xong backend đưa về app / web kèm vé (xem
/// `GoogleCallbackScreen`). Máy chủ chưa cấu hình Google thì báo thay vì mở trang.
class _GoogleButton extends ConsumerWidget {
  const _GoogleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final busy = ref.watch(authControllerProvider).isLoading;
    Future<void> start() async {
      final messenger = ScaffoldMessenger.of(context);
      final uri = await ref
          .read(authControllerProvider.notifier)
          .googleLoginUri();
      if (uri == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.authGoogleSoon)));
        return;
      }
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );
      if (!ok) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.authGoogleSoon)));
      }
    }

    return OutlinedButton(
      onPressed: busy ? null : start,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        foregroundColor: SoftPalette.night,
        backgroundColor: SoftPalette.mist,
        side: const BorderSide(color: SoftPalette.sky),
        textStyle: context.textStyles.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'G',
            style: context.textStyles.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: SoftPalette.skyDeep,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(l10n.authContinueGoogle),
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

/// Vòng tròn xanh nhạt làm nền trang trí ở góc màn đăng nhập / đăng ký.
class _Blob extends StatelessWidget {
  const _Blob(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
