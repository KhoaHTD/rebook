import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/core/realtime/realtime_client.dart';
import 'package:book_marketplace/features/auction/domain/auction_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

class ApiAuctionRepository implements AuctionRepository {
  ApiAuctionRepository(this._client, this._realtime);

  final api.RestClient _client;
  final RealtimeClient _realtime;

  @override
  Future<List<AuctionSession>> sessions({SessionStatus? status}) =>
      guardApi(() async {
        final list = await _client.auctions.listSessions(
          status: status == null
              ? null
              : toApiEnum(api.SessionStatus.values, status),
        );
        return list.map((e) => e.toDomain()).toList();
      });

  @override
  Future<(AuctionSession, List<Lot>)> catalogue(String sessionId) =>
      guardApi(() async {
        final dto = await _client.auctions.getSessionCatalogue(id: sessionId);
        return (
          dto.session.toDomain(),
          dto.lots.map((e) => e.toDomain()).toList(),
        );
      });

  @override
  Future<Lot> lot(String lotId) => guardApi(
    () async => (await _client.auctions.getLot(id: lotId)).toDomain(),
  );

  @override
  Future<List<Bid>> lotBids(String lotId) => guardApi(
    () async =>
        (await _client.auctions.listLotBids(id: lotId))
            .map((e) => e.toDomain())
            .toList(),
  );

  @override
  Future<Registration?> myRegistration(String sessionId) async {
    try {
      return await guardApi(
        () async =>
            (await _client.auctions.getMyRegistration(id: sessionId))
                .toDomain(),
      );
    } on ServerException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Registration>> myRegistrations() => guardApi(
    () async => (await _client.auctions.listMyRegistrations())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<Registration> register(String sessionId, int deposit) => guardApi(
    () async => (await _client.auctions.registerSession(
      id: sessionId,
      body: api.RegisterSessionRequest(
        agreeRules: true,
        depositAmount: deposit,
      ),
    )).toDomain(),
  );

  @override
  Future<Lot> watch(String lotId, {required bool on}) => guardApi(
    () async => (await _client.auctions.watchLot(
      id: lotId,
      body: api.WatchRequest(watch: on),
    )).toDomain(),
  );

  @override
  Future<void> setProxyBid(String lotId, int maxAmount) => guardApi(
    () => _client.auctions.setProxyBid(
      id: lotId,
      body: api.ProxyBidRequest(maxAmount: maxAmount),
    ),
  );

  @override
  Future<Bid> placeBid(String lotId, int amount) => guardApi(
    () async => (await _client.auctions.placeBid(
      id: lotId,
      body: api.PlaceBidRequest(amount: amount),
    )).toDomain(),
  );

  @override
  Future<SessionState> sessionState(String sessionId) => guardApi(
    () async =>
        (await _client.auctions.getSessionState(id: sessionId)).toDomain(),
  );

  @override
  Stream<AuctionEvent> events(String sessionId) => _realtime
      .subscribe('/topic/sessions/$sessionId')
      .map((json) => api.AuctionEventDto.fromJson(json).toDomain())
      .where((e) => e != null)
      .cast<AuctionEvent>();

  @override
  Stream<void> get reconnects => _realtime.onReconnect;

  @override
  Future<SessionResult> results(String sessionId) => guardApi(
    () async =>
        (await _client.auctions.getSessionResults(id: sessionId)).toDomain(),
  );

  @override
  Future<Wallet> wallet() =>
      guardApi(() async => (await _client.wallet.getWallet()).toDomain());

  @override
  Future<List<SecondChanceOffer>> secondChanceOffers() => guardApi(
    () async => (await _client.auctions.listSecondChanceOffers())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<Order> acceptSecondChance(String id) => guardApi(
    () async =>
        (await _client.auctions.acceptSecondChanceOffer(id: id)).toDomain(),
  );

  @override
  Future<SecondChanceOffer> declineSecondChance(String id) => guardApi(
    () async =>
        (await _client.auctions.declineSecondChanceOffer(id: id)).toDomain(),
  );
}
