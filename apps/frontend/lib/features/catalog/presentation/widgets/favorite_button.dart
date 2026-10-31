import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/favorites_providers.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';

/// Nút trái tim thêm / bỏ một tin khỏi danh sách yêu thích. Chưa đăng nhập → đăng nhập rồi quay lại.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final on = ref.watch(favoriteIdsProvider).contains(listingId);
    return IconButton(
      tooltip: on ? l10n.favRemove : l10n.favAdd,
      icon: Icon(
        on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: on ? context.appColors.live : null,
      ),
      onPressed: () async {
        if (!ref.read(sessionControllerProvider).isSignedIn) {
          context.go(
            Uri(
              path: Routes.login,
              queryParameters: {'from': Routes.listing(listingId)},
            ).toString(),
          );
          return;
        }
        final ok = await ref
            .read(favoriteActionsProvider.notifier)
            .setFavorite(listingId, on: !on);
        if (!ok && context.mounted) {
          showErrorSnack(context, ref.read(favoriteActionsProvider).error!);
        }
      },
    );
  }
}
