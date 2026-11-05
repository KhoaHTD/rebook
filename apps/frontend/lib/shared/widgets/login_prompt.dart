import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/settings/intro_state.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Đường dẫn tới màn đăng nhập, nhớ trang đang đứng để quay lại sau khi đăng nhập xong.
String loginPath(String from) =>
    Uri(path: Routes.login, queryParameters: {'from': from}).toString();

/// Hộp thoại mời đăng nhập / đăng ký. Khách bấm vào việc cần tài khoản (thêm giỏ, yêu thích…) thì hiện ra
/// thay vì bị đẩy sang trang đăng nhập; "Để sau" đóng lại và tiếp tục xem.
/// [welcome]: bản chào lúc mở app, nút từ chối là "Chỉ xem sách".
Future<void> showLoginRequired(
  BuildContext context, {
  String? from,
  bool welcome = false,
}) {
  final l10n = context.l10n;
  final target = from ?? GoRouterState.of(context).uri.toString();
  final router = GoRouter.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialog) {
      final c = dialog.appColors;
      final text = dialog.textStyles;
      void leave(String path) {
        Navigator.pop(dialog);
        router.go(path);
      }

      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Glass(
            tint: dialog.colors.surface.withValues(alpha: 0.94),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: c.tintSoft,
                    child: Icon(
                      welcome
                          ? Icons.auto_stories_rounded
                          : Icons.lock_outline_rounded,
                      color: c.tint,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  welcome ? l10n.guestWelcomeTitle : l10n.loginRequiredTitle,
                  textAlign: TextAlign.center,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  welcome ? l10n.guestWelcomeBody : l10n.loginRequiredBody,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: c.secondaryText),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => leave(loginPath(target)),
                  child: Text(l10n.login),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => leave(Routes.register),
                  child: Text(l10n.register),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialog),
                  child: Text(welcome ? l10n.guestBrowseOnly : l10n.loginLater),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Đặt trong khung app: khách (chưa đăng nhập) vào app thì hiện lời chào mời đăng nhập một lần mỗi lần chạy.
class GuestWelcomeTrigger extends ConsumerStatefulWidget {
  const GuestWelcomeTrigger({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<GuestWelcomeTrigger> createState() =>
      _GuestWelcomeTriggerState();
}

class _GuestWelcomeTriggerState extends ConsumerState<GuestWelcomeTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = ref.read(sessionControllerProvider);
      if (session.status != AuthStatus.signedOut) return;
      if (ref.read(guestWelcomeShownProvider)) return;
      ref.read(guestWelcomeShownProvider.notifier).mark();
      showLoginRequired(context, welcome: true, from: Routes.home);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
