import 'dart:async';

import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/core/realtime/realtime_client.dart';
import 'package:book_marketplace/features/auction/data/auction_mapper.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/features/auction/domain/auction_repository.dart';

/// Đấu giá qua API thật.
///
/// Phòng đấu giá là của **phiên**: `GET /sessions/{id}/state` cho ảnh chụp trạng thái,
/// rồi nghe WebSocket `sessions/{id}` (sự kiện `AuctionEvent`: LOT_OPENED, BID_PLACED,
/// LOT_CLOSED, SESSION_*). Màn phòng mở theo id lô nên repository tự tìm phiên chứa lô.
class ApiAuctionRepository implements AuctionRepository {
  ApiAuctionRepository(this._client, this._realtime);

  final api.RestClient _client;
  final RealtimeClient _realtime;

  /// Ngữ cảnh phòng theo id lô — để trả giá không phải tải lại thông tin phiên.
  final _rooms = <int, (int, RoomContext)>{};

  /// Yêu cầu phòng đang mở của phiên lấy lại ảnh chụp (sau khi đổi giá tối đa...).
  final _refresh = StreamController<int>.broadcast();

  /// Phiên đang nhận đăng ký / sắp chạy / đang chạy.
  static const _activeSessions = {
    api.SessionStatus.published,
    api.SessionStatus.postponed,
    api.SessionStatus.confirmed,
    api.SessionStatus.live,
    api.SessionStatus.paused,
  };

  @override
  Future<List<Auction>> listAuctions() => guardApi(() async {
    final page = await _client.auction.getSessions(size: 50);
    final sessions = (page.items ?? const <api.SessionSummary>[])
        .where((s) => _activeSessions.contains(s.status))
        .toList();
    final details = await Future.wait([
      for (final s in sessions) _client.auction.getSessionsId(id: s.id!),
    ]);
    return [
      for (final d in details)
        for (final lot in d.lots ?? const <api.LotPublic>[])
          if (lot.status == api.LotStatus.scheduled ||
              lot.status == api.LotStatus.open)
            lot.toAuction(d),
    ];
  });

  @override
  Stream<Auction> watchAuction(String id) async* {
    final (sessionId, ctx) = await guardApi(() => _openRoom(int.parse(id)));
    final state = await guardApi(
      () => _client.auction.getSessionsIdState(id: sessionId),
    );
    _applyState(ctx, state);

    var current = await _currentLot(ctx, state, int.parse(id));
    yield current;

    // Gộp sự kiện WebSocket với yêu cầu làm mới cục bộ (null = lấy lại ảnh chụp).
    final events = StreamController<Map<String, dynamic>?>();
    final subs = [
      _realtime.subscribe('sessions/$sessionId').listen(events.add),
      _refresh.stream
          .where((s) => s == sessionId)
          .listen((_) => events.add(null)),
    ];
    try {
      await for (final json in events.stream) {
        final event = json == null ? null : api.AuctionEvent.fromJson(json);
        final lot = event?.lot;
        if (event?.type == 'BID_PLACED' && lot != null) {
          await _ensureLotDetail(ctx, lot.id);
          current = lot.toAuction(ctx, previous: current);
        } else {
          // Lô mới mở / lô chốt / phiên đổi trạng thái: lấy lại ảnh chụp đầy đủ
          // (cập nhật hạn mức đã dùng, giá tối đa, lô hiện tại).
          final fresh = await guardApi(
            () => _client.auction.getSessionsIdState(id: sessionId),
          );
          _applyState(ctx, fresh);
          current = await _currentLot(
            ctx,
            fresh,
            int.parse(id),
            previous: current,
          );
        }
        yield current;
      }
    } finally {
      for (final sub in subs) {
        await sub.cancel();
      }
      await events.close();
    }
  }

  @override
  Future<Auction> placeBid(String id, int amount) => guardApi(() async {
    final lotId = int.parse(id);
    final res = await _client.auction.postLotsIdBids(
      id: lotId,
      body: api.BidRequest(amount: amount),
    );
    final (_, ctx) = _rooms[lotId] ?? await _openRoom(lotId);
    ctx.me = res.me ?? ctx.me;
    final live = res.lot;
    if (live == null) throw const UnknownException('Empty bid response');
    await _ensureLotDetail(ctx, live.id);
    return live.toAuction(ctx);
  });

  @override
  Future<LotDetail> getLot(String id) => guardApi(() async {
    final detail = await _client.auction.getLotsId(id: int.parse(id));
    final sessionId = detail.lot?.sessionId;
    if (sessionId == null) {
      throw const ServerException(404, 'Lot has no session');
    }
    final session = await _client.auction.getSessionsId(id: sessionId);
    return detail.toDomain(session);
  });

  @override
  Future<bool> setFollowing(String id, {required bool following}) =>
      guardApi(() async {
        final res = following
            ? await _client.auction.postLotsIdWatch(id: int.parse(id))
            : await _client.auction.deleteLotsIdWatch(id: int.parse(id));
        return res['watching'] ?? following;
      });

  @override
  Future<LotDetail> register(String lotId) => guardApi(() async {
    final detail = await _client.auction.getLotsId(id: int.parse(lotId));
    final sessionId = detail.lot?.sessionId;
    if (sessionId == null) {
      throw const ServerException(404, 'Lot has no session');
    }
    await _client.auction.postSessionsIdRegister(
      id: sessionId,
      body: const api.RegisterRequest(agreeRules: true),
    );
    final session = await _client.auction.getSessionsId(id: sessionId);
    return detail.toDomain(session);
  });

  @override
  Future<Auction> setProxy(String id, int? maxAmount) => guardApi(() async {
    final lotId = int.parse(id);
    if (maxAmount == null) {
      await _client.auction.deleteLotsIdProxyBid(id: lotId);
    } else {
      await _client.auction.putLotsIdProxyBid(
        id: lotId,
        body: api.ProxyBidRequest(maxAmount: maxAmount),
      );
    }
    final (sessionId, ctx) = _rooms[lotId] ?? await _openRoom(lotId);
    final state = await _client.auction.getSessionsIdState(id: sessionId);
    _applyState(ctx, state);
    _refresh.add(sessionId);
    return _currentLot(ctx, state, lotId);
  });

  // ---- Nội bộ ----

  /// Tìm phiên chứa lô và tải thông tin phiên (thời lượng lô, số lô, đăng ký của tôi).
  Future<(int, RoomContext)> _openRoom(int lotId) async {
    final detail = await _client.auction.getLotsId(id: lotId);
    final sessionId = detail.lot?.sessionId;
    if (sessionId == null) {
      throw const ServerException(404, 'Lô chưa được xếp vào phiên nào');
    }
    final session = await _client.auction.getSessionsId(id: sessionId);
    final ctx = RoomContext(session: session, me: session.myRegistration);
    ctx.lots[lotId] = detail;
    return _rooms[lotId] = (sessionId, ctx);
  }

  void _applyState(RoomContext ctx, api.SessionState state) {
    ctx.me = state.me ?? ctx.me;
    ctx.proxyMax = state.myProxyMax;
  }

  Future<void> _ensureLotDetail(RoomContext ctx, int? lotId) async {
    if (lotId == null || ctx.lots.containsKey(lotId)) return;
    ctx.lots[lotId] = await guardApi(
      () => _client.auction.getLotsId(id: lotId),
    );
  }

  /// Lô đang hiển thị trong phòng: lô phiên đang chạy, hoặc chính lô được mở khi phiên chưa chạy.
  Future<Auction> _currentLot(
    RoomContext ctx,
    api.SessionState state,
    int requestedLotId, {
    Auction? previous,
  }) async {
    final live = state.currentLot;
    if (live != null) {
      await _ensureLotDetail(ctx, live.id);
      return live.toAuction(ctx, previous: previous);
    }
    final lot = (ctx.session.lots ?? const <api.LotPublic>[]).firstWhere(
      (l) => l.id == requestedLotId,
      orElse: () => ctx.lots[requestedLotId]?.lot ?? const api.LotPublic(),
    );
    return lot.toAuction(ctx.session);
  }
}
