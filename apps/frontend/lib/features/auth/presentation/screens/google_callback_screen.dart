import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/app/theme/soft_palette.dart';
import 'package:book_marketplace/features/auth/presentation/providers/auth_controller.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';

/// Đích quay về của đăng nhập Google: nhận vé một lần trên địa chỉ, đổi lấy token rồi vào app
/// (router tự chuyển khỏi màn này khi đã đăng nhập). Lỗi thì hiện thông báo và nút về đăng nhập.
class GoogleCallbackScreen extends ConsumerStatefulWidget {
  const GoogleCallbackScreen({super.key, this.ticket, this.error});

  final String? ticket;
  final String? error;

  @override
  ConsumerState<GoogleCallbackScreen> createState() =>
      _GoogleCallbackScreenState();
}

class _GoogleCallbackScreenState extends ConsumerState<GoogleCallbackScreen> {
  @override
  void initState() {
    super.initState();
    final ticket = widget.ticket;
    if (ticket != null && ticket.isNotEmpty && widget.error == null) {
      Future.microtask(() {
        if (mounted) {
          ref
              .read(authControllerProvider.notifier)
              .loginWithGoogleTicket(ticket);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);
    final failed =
        widget.error != null ||
        widget.ticket == null ||
        widget.ticket!.isEmpty ||
        state.hasError;
    final message = state.hasError
        ? errorMessage(context, state.error!)
        : (widget.error == 'access_denied'
              ? l10n.authGoogleCancelled
              : l10n.authGoogleFailed);
    return Scaffold(
      backgroundColor: SoftPalette.paper,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!failed) ...[
                const CircularProgressIndicator(color: SoftPalette.night),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.authGoogleWorking,
                  style: context.textStyles.titleMedium,
                ),
              ] else ...[
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: SoftPalette.night,
                    foregroundColor: SoftPalette.cream,
                    shape: const StadiumBorder(),
                    minimumSize: const Size(220, 52),
                  ),
                  onPressed: () => context.go(Routes.login),
                  child: Text(l10n.login),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
