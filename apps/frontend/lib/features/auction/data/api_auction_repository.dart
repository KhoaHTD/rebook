import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/core/realtime/realtime_client.dart';
import 'package:book_marketplace/features/auction/domain/auction_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/data/session_loader.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

class ApiAuctionRepository implements AuctionRepository {
  ApiAuctionRepository(this._client, this._realtime);

  final api.RestClient _client;
  final RealtimeClient _realtime;

  /// Lô đã tải, để sự kiện realtime (chỉ mang `LotLive`) giữ được sách / ước giá.
  final _knownLots = <int, Lot>{};

  void _remember(Iterable<Lot> lots) {
    for (final l in lots) {
      final id = int.tryParse(l.id);
      if (id != null) _knownLots[id] = l;
    }
  }

  @override
  Future<List<AuctionSession>> sessions({SessionStatus? status}) =>
      guardApi(() async {
        final res = await _client.auction.getSessions(
          status: status == null ? null : sessionStatusToApi(status),
          size: 100,
        );
        return [for (final s in res.items.orEmpty) s.toDomain()];
      });

  @override
  Future<(AuctionSession, List<Lot>)> catalogue(String sessionId) => guardApi(
    () async {
      final detail = await _client.auction.getSessionsId(id: apiId(sessionId));
      final lots = detail.lotsToDomain();
      _remember(lots);
      return (detail.sessionToDomain(), lots);
    },
  );

  @override
  Future<Lot> lot(String lotId) => guardApi(() async {
    final lot = (await _client.auction.getLotsId(id: apiId(lotId))).toDomain();
    _remember([lot]);
    return lot;
  });

  /// Backend chỉ trả lịch sử trả giá của lô đang đấu (`recentBids` trong state phiên).
  @override
  Future<List<Bid>> lotBids(String lotId) => guardApi(() async {
    final detail = await _client.auction.getLotsId(id: apiId(lotId));
    final sessionId = detail.lot?.sessionId;
    if (sessionId == null) return const [];
    final state = await _client.auction.getSessionsIdState(id: sessionId);
    final live = state.currentLot;
    if (live == null || '${live.id}' != lotId) return const [];
    return bidsToDomain(live);
  });

  @override
  Future<Registration?> myRegistration(String sessionId) => guardApi(() async {
    final detail = await _client.auction.getSessionsId(id: apiId(sessionId));
    return detail.myRegistration?.toDomain(
      sessionTitle: detail.session?.title ?? '',
    );
  });

  @override
  Future<List<Registration>> myRegistrations() => guardApi(() async {
    final regs = await _client.auction.getMeRegistrations();
    final sessions = await _client.auction.getSessions(size: 100);
    final titles = {for (final s in sessions.items.orEmpty) s.id: s.title};
    return [
      for (final r in regs) r.toDomain(sessionTitle: titles[r.sessionId] ?? ''),
    ];
  });

  /// Backend lấy tiền cọc theo cấu hình phiên. Chọn cọc cao hơn → cọc thêm phần chênh.
  @override
  Future<void> cancelRegistration(String sessionId) => guardApi(
    () => _client.auction.deleteSessionsIdRegister(id: apiId(sessionId)),
  );

  @override
  Future<Registration> register(String sessionId, int deposit) =>
      guardApi(() async {
        final id = apiId(sessionId);
        var reg = await _client.auction.postSessionsIdRegister(
          id: id,
          body: const api.SessionRegisterRequest(agreeRules: true),
        );
        final extra = deposit - (reg.depositAmount?.round() ?? deposit);
        if (extra > 0) {
          reg = await _client.auction.postSessionsIdDeposit(
            id: id,
            body: api.AddDepositRequest(amount: extra),
          );
        }
        final detail = await _client.auction.getSessionsId(id: id);
        return reg.toDomain(sessionTitle: detail.session?.title ?? '');
      });

  @override
  Future<Lot> watch(String lotId, {required bool on}) => guardApi(() async {
    final id = apiId(lotId);
    if (on) {
      await _client.auction.postLotsIdWatch(id: id);
    } else {
      await _client.auction.deleteLotsIdWatch(id: id);
    }
    return (await _client.auction.getLotsId(id: id)).toDomain();
  });

  @override
  Future<void> clearProxyBid(String lotId) =>
      guardApi(() => _client.auction.deleteLotsIdProxyBid(id: apiId(lotId)));

  @override
  Future<void> setProxyBid(String lotId, int maxAmount) => guardApi(
    () => _client.auction.putLotsIdProxyBid(
      id: apiId(lotId),
      body: api.ProxyBidRequest(maxAmount: maxAmount),
    ),
  );

  @override
  Future<Bid> placeBid(String lotId, int amount) => guardApi(() async {
    final res = await _client.auction.postLotsIdBids(
      id: apiId(lotId),
      body: api.BidRequest(amount: amount),
    );
    return Bid(
      id: '$lotId-${res.lot?.bidCount ?? DateTime.now().microsecondsSinceEpoch}',
      lotId: lotId,
      paddleNumber: res.me?.paddle ?? '',
      amount: amount,
      createdAt: DateTime.now(),
    );
  });

  @override
  Future<SessionState> sessionState(String sessionId) => guardApi(() async {
    final state = await loadSessionState(_client, sessionId);
    _remember(state.lots);
    return state;
  });

  @override
  Stream<AuctionEvent> events(String sessionId) => _realtime
      .subscribe('sessions/$sessionId')
      .map(api.AuctionEvent.fromJson)
      .map((e) => auctionEventToDomain(e, baseLot: (id) => _knownLots[id]))
      .where((e) => e != null)
      .cast<AuctionEvent>();

  @override
  Stream<void> get reconnects => _realtime.onReconnect;

  /// Kết quả từng lô; "tôi thắng" suy ra từ số paddle của mình trong phiên.
  @override
  Future<SessionResult> results(String sessionId) => guardApi(() async {
    final id = apiId(sessionId);
    final detail = await _client.auction.getSessionsId(id: id);
    final results = await _client.auction.getSessionsIdResults(id: id);
    final myPaddle = detail.myRegistration?.paddle;
    return SessionResult(
      session: detail.sessionToDomain(),
      results: [
        for (final r in results)
          LotResult(
            lotId: '${r.lotId}',
            lotNumber: r.lotNumber ?? 0,
            title: r.title ?? '',
            outcome: lotOutcomeToDomain(r.result) ?? LotOutcome.noBids,
            hammerPrice: r.hammerPrice?.round(),
            winnerPaddle: r.winnerPaddle,
            wonByMe: myPaddle != null && r.winnerPaddle == myPaddle,
          ),
      ],
    );
  });

  @override
  Future<Wallet> wallet() =>
      guardApi(() async => (await _client.wallet.getWallet()).toDomain());

  @override
  Future<List<AuctionSession>> watchedSessions() => guardApi(
    () async => [
      for (final s in await _client.auction.getMeWatchedSessions())
        s.toDomain(),
    ],
  );

  @override
  Future<void> watchSession(String sessionId, {required bool on}) =>
      guardApi(() async {
        final id = apiId(sessionId);
        if (on) {
          await _client.auction.postSessionsIdWatch(id: id);
        } else {
          await _client.auction.deleteSessionsIdWatch(id: id);
        }
      });

  /// Backend không có bảng lời mời riêng: lời mời là hoá đơn lô có cờ `secondChance`.
  @override
  Future<List<SecondChanceOffer>> secondChanceOffers() => guardApi(() async {
    final res = await _client.order.getOrders(size: 100);
    final offers = [
      for (final o in res.items.orEmpty)
        if (o.secondChance ?? false) o,
    ];
    return Future.wait([
      for (final o in offers)
        (o.lotId == null
                ? Future<int>.value(0)
                : _client.auction
                      .getLotsId(id: o.lotId!)
                      .then((d) => d.lot?.lotNumber ?? 0)
                      .catchError((Object _) => 0))
            .then((n) => o.toSecondChance(lotNumber: n)),
    ]);
  });

  /// Nhận lời mời = trả hoá đơn lô; app mở hoá đơn để chọn giao hàng và thanh toán.
  @override
  Future<Order> acceptSecondChance(String id) => guardApi(
    () async => (await _client.order.getOrdersId(id: apiId(id))).toDomain(),
  );

  @override
  Future<SecondChanceOffer> declineSecondChance(String id) =>
      guardApi(() async {
        await _client.auction.postOrdersIdDeclineSecondChance(id: apiId(id));
        final offers = await secondChanceOffers();
        return offers
            .firstWhere((o) => o.id == id)
            .copyWith(status: SecondChanceStatus.declined);
      });
}
