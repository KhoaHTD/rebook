import 'package:book_marketplace/features/auction/domain/auction_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

/// Phiên "LIVE" chạy thật trong bộ nhớ: mỗi lô 60 giây, có bot trả giá.
class FakeAuctionRepository implements AuctionRepository {
  FakeAuctionRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<AuctionSession>> sessions({SessionStatus? status}) =>
      fakeCall(() => _store.listSessions(status: status));

  @override
  Future<(AuctionSession, List<Lot>)> catalogue(String sessionId) =>
      fakeCall(() {
        final c = _store.catalogue(sessionId);
        return (c.session, c.lots);
      });

  @override
  Future<Lot> lot(String lotId) => fakeCall(() => _store.lot(lotId));

  @override
  Future<List<Bid>> lotBids(String lotId) =>
      fakeCall(() => _store.lotBids(lotId));

  @override
  Future<Registration?> myRegistration(String sessionId) =>
      fakeCall(() => _store.myRegistration(sessionId), ms: 80);

  @override
  Future<List<Registration>> myRegistrations() =>
      fakeCall(_store.myRegistrations);

  @override
  Future<Registration> register(String sessionId, int deposit) =>
      fakeCall(() => _store.registerSession(sessionId, deposit), ms: 500);

  @override
  Future<List<AuctionSession>> watchedSessions() =>
      fakeCall(_store.watchedSessionList, ms: 80);

  @override
  Future<void> watchSession(String sessionId, {required bool on}) =>
      fakeCall(() => _store.setSessionWatch(sessionId, on: on), ms: 60);

  @override
  Future<Lot> watch(String lotId, {required bool on}) =>
      fakeCall(() => _store.watch(lotId, on: on), ms: 80);

  @override
  Future<void> setProxyBid(String lotId, int maxAmount) =>
      fakeCall(() => _store.setProxy(lotId, maxAmount));

  @override
  Future<Bid> placeBid(String lotId, int amount) =>
      fakeCall(() => _store.placeBid(lotId, amount), ms: 120);

  @override
  Future<SessionState> sessionState(String sessionId) =>
      fakeCall(() => _store.sessionState(sessionId), ms: 120);

  @override
  Stream<AuctionEvent> events(String sessionId) =>
      _store.sessionEvents(sessionId);

  @override
  Stream<void> get reconnects => const Stream.empty();

  @override
  Future<SessionResult> results(String sessionId) =>
      fakeCall(() => _store.sessionResults(sessionId));

  @override
  Future<Wallet> wallet() =>
      fakeCall(() => _store.walletOf(_store.currentUserId!));

  @override
  Future<List<SecondChanceOffer>> secondChanceOffers() =>
      fakeCall(_store.mySecondChances);

  @override
  Future<Order> acceptSecondChance(String id) =>
      fakeCall(() => _store.acceptSecondChance(id), ms: 300);

  @override
  Future<SecondChanceOffer> declineSecondChance(String id) =>
      fakeCall(() => _store.declineSecondChance(id), ms: 150);
}
