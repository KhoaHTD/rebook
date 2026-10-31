import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/catalog/data/catalog_repository_provider.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';

part 'favorites_providers.g.dart';

/// Sách tôi đã thả tim (SRS 3, mở rộng), mới nhất trước.
@riverpod
Future<List<Listing>> favoriteListings(Ref ref) {
  ref.watchArea(DataArea.favorites);
  if (ref.watch(currentUserProvider) == null) return Future.value(const []);
  return ref.watch(catalogRepositoryProvider).favorites();
}

/// Id các tin đã thả tim, để tô đặc trái tim ở mọi nơi.
@riverpod
Set<String> favoriteIds(Ref ref) => {
  for (final l
      in ref.watch(favoriteListingsProvider).value ?? const <Listing>[])
    l.id,
};

@riverpod
class FavoriteActions extends _$FavoriteActions {
  @override
  FutureOr<void> build() {}

  Future<bool> setFavorite(String listingId, {required bool on}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(catalogRepositoryProvider).setFavorite(listingId, on: on),
    );
    if (!state.hasError) {
      ref.read(dataChangesProvider.notifier).bump(DataArea.favorites);
    }
    return !state.hasError;
  }
}
