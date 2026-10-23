import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/auction/data/auction_repository_provider.dart';
import 'package:book_marketplace/features/auction/domain/live_reducer.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

part 'auction_providers.g.dart';

@riverpod
Future<List<AuctionSession>> auctionSessions(Ref ref) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(auctionRepositoryProvider).sessions();
}

@riverpod
Future<(AuctionSession, List<Lot>)> sessionCatalogue(Ref ref, String id) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(auctionRepositoryProvider).catalogue(id);
}

@riverpod
Future<Lot> lotDetail(Ref ref, String id) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(auctionRepositoryProvider).lot(id);
}

@riverpod
Future<List<Bid>> lotBids(Ref ref, String id) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(auctionRepositoryProvider).lotBids(id);
}

@riverpod
Future<Registration?> sessionRegistration(Ref ref, String sessionId) {
  ref.watchArea(DataArea.auctions);
  if (ref.watch(currentUserProvider) == null) return Future.value();
  return ref.watch(auctionRepositoryProvider).myRegistration(sessionId);
}

@riverpod
Future<List<Registration>> myRegistrations(Ref ref) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(auctionRepositoryProvider).myRegistrations();
}

@riverpod
Future<SessionResult> sessionResults(Ref ref, String sessionId) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(auctionRepositoryProvider).results(sessionId);
}

@riverpod
Future<Wallet> auctionWallet(Ref ref) {
  ref.watchArea(DataArea.wallet);
  return ref.watch(auctionRepositoryProvider).wallet();
}

/// Trạng thái phòng đấu giá kèm chênh lệch đồng hồ server − máy.
class RoomState {
  const RoomState(this.snapshot, this.serverOffset);

  final SessionState snapshot;

  /// Cộng vào giờ máy để ra giờ server — đếm ngược khớp server (SRS 10.3).
  final Duration serverOffset;
}

/// Phòng đấu giá: ảnh chụp trạng thái + sự kiện realtime.
/// Kết nối lại → tải lại ảnh chụp (server giữ đồng hồ và giá).
@riverpod
class LiveRoom extends _$LiveRoom {
  StreamSubscription<AuctionEvent>? _events;
  StreamSubscription<void>? _reconnects;

  @override
  Future<RoomState> build(String sessionId) async {
    final repo = ref.watch(auctionRepositoryProvider);
    ref.onDispose(() {
      _events?.cancel();
      _reconnects?.cancel();
    });
    final snapshot = await repo.sessionState(sessionId);
    _events = repo.events(sessionId).listen(_onEvent);
    _reconnects = repo.reconnects.listen((_) => _reload());
    return _wrap(snapshot);
  }

  RoomState _wrap(SessionState s) =>
      RoomState(s, s.serverTime.difference(DateTime.now()));

  Future<void> _reload() async {
    final snapshot = await ref
        .read(auctionRepositoryProvider)
        .sessionState(sessionId);
    state = AsyncData(_wrap(snapshot));
  }

  void _onEvent(AuctionEvent e) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(_wrap(applyAuctionEvent(current.snapshot, e)));
    // Hạn mức đã cam kết đổi khi lô đóng / bị vượt giá: hỏi lại server.
    if (e is LotClosed || e is BidPlaced) unawaited(_refreshRegistration());
    if (e is SessionEnded || e is LotClosed) {
      ref.read(dataChangesProvider.notifier).bump(DataArea.auctions);
    }
  }

  Future<void> _refreshRegistration() async {
    if (state.value?.snapshot.myRegistration == null) return;
    final reg = await ref
        .read(auctionRepositoryProvider)
        .myRegistration(sessionId);
    final current = state.value;
    if (current != null && reg != null) {
      state = AsyncData(
        RoomState(
          current.snapshot.copyWith(myRegistration: reg),
          current.serverOffset,
        ),
      );
    }
  }
}

/// Bấm "Trả giá". Lỗi 409 (giá đã đổi, đang dẫn, vượt hạn mức) hiển thị qua state.
@riverpod
class BidAction extends _$BidAction {
  @override
  FutureOr<void> build(String sessionId) {}

  Future<bool> bid(String lotId, int amount) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(auctionRepositoryProvider).placeBid(lotId, amount),
    );
    return !state.hasError;
  }

  Future<bool> setProxy(String lotId, int max) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(auctionRepositoryProvider).setProxyBid(lotId, max),
    );
    return !state.hasError;
  }
}

/// Đăng ký phiên + khóa cọc; theo dõi lô.
@riverpod
class AuctionActions extends _$AuctionActions {
  @override
  FutureOr<void> build() {}

  Future<Registration?> register(String sessionId, int deposit) async {
    state = const AsyncLoading();
    Registration? reg;
    state = await AsyncValue.guard(() async {
      reg = await ref
          .read(auctionRepositoryProvider)
          .register(sessionId, deposit);
    });
    if (reg != null) {
      final changes = ref.read(dataChangesProvider.notifier);
      for (final area in [DataArea.auctions, DataArea.wallet]) {
        changes.bump(area);
      }
    }
    return reg;
  }

  Future<void> watch(String lotId, {required bool on}) async {
    state = await AsyncValue.guard(
      () => ref.read(auctionRepositoryProvider).watch(lotId, on: on),
    );
    ref.read(dataChangesProvider.notifier).bump(DataArea.auctions);
  }
}

/// Nhóm hiển thị trên trang Đấu giá.
enum SessionTab {
  live,
  upcoming,
  ended;

  bool matches(SessionStatus s) => switch (this) {
    live => s == SessionStatus.live || s == SessionStatus.paused,
    upcoming =>
      s == SessionStatus.published ||
          s == SessionStatus.confirmed ||
          s == SessionStatus.postponed,
    ended => s == SessionStatus.ended || s == SessionStatus.cancelled,
  };
}
