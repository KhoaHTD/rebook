import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/auction/data/auction_repository_provider.dart';
import 'package:book_marketplace/shared/domain/auction.dart';

part 'session_watch_providers.g.dart';

/// Phiên tôi theo dõi (phiên yêu thích).
@riverpod
Future<List<AuctionSession>> watchedSessions(Ref ref) {
  ref.watchArea(DataArea.auctions);
  if (ref.watch(currentUserProvider) == null) return Future.value(const []);
  return ref.watch(auctionRepositoryProvider).watchedSessions();
}

@riverpod
Set<String> watchedSessionIds(Ref ref) => {
  for (final s
      in ref.watch(watchedSessionsProvider).value ?? const <AuctionSession>[])
    s.id,
};

@riverpod
class SessionWatchActions extends _$SessionWatchActions {
  @override
  FutureOr<void> build() {}

  Future<bool> setWatch(String sessionId, {required bool on}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(auctionRepositoryProvider).watchSession(sessionId, on: on),
    );
    if (!state.hasError) {
      ref.read(dataChangesProvider.notifier).bump(DataArea.auctions);
    }
    return !state.hasError;
  }
}
