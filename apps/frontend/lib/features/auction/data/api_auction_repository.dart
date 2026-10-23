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
}
