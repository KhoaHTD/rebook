import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/auction/presentation/providers/session_watch_providers.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';

/// Nút trái tim theo dõi cả phiên (khác với theo dõi từng lô). Chưa đăng nhập → đăng nhập rồi quay lại.
class SessionWatchButton extends ConsumerWidget {
  const SessionWatchButton({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final on = ref.watch(watchedSessionIdsProvider).contains(sessionId);
    return IconButton(
      tooltip: on ? l10n.sessUnwatch : l10n.sessWatch,
      icon: Icon(
        on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: on ? context.appColors.live : null,
      ),
      onPressed: () async {
        if (!ref.read(sessionControllerProvider).isSignedIn) {
          context.go(
            Uri(
              path: Routes.login,
              queryParameters: {'from': Routes.session(sessionId)},
            ).toString(),
          );
          return;
        }
        final ok = await ref
            .read(sessionWatchActionsProvider.notifier)
            .setWatch(sessionId, on: !on);
        if (!ok && context.mounted) {
          showErrorSnack(context, ref.read(sessionWatchActionsProvider).error!);
        }
      },
    );
  }
}
