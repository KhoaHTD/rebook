import 'dart:async';
import 'dart:math';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/features/auction/domain/auction_repository.dart';
import 'package:book_marketplace/shared/domain/book.dart';

/// Số bài của người dùng trong dữ liệu giả.
const fakeMyPaddle = '#007';

/// Giả lập phiên đấu giá: lô a1 đang chạy, các lô còn lại sắp mở.
/// "Người khác" thỉnh thoảng trả giá để thấy realtime; có soft close và giá tối đa tự trả.
class FakeAuctionRepository implements AuctionRepository {
  FakeAuctionRepository({
    this.simulateOtherBidders = true,
    this.rivalCap = 2400000,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _seed();
  }

  final bool simulateOtherBidders;

  /// Người khác ngừng trả khi giá vượt mức này.
  final int rivalCap;
  final DateTime Function() _now;

  final _auctions = <String, Auction>{};
  final _lots = <String, LotDetail>{};
  final _reserves = <String, int>{};
  final _changes = StreamController<Auction>.broadcast();
  final _random = Random();

  static const _rivals = ['#012', '#027', '#031', '#044'];
  static const _softClose = Duration(seconds: 15);

  /// Bước giá theo bậc (giống backend).
  static int increment(int price) => bidIncrementFor(price);

  void _seed() {
    final now = _now();
    const checklistGood = [
      InspectionItem(check: InspectionCheck.fullPages, ok: true),
      InspectionItem(check: InspectionCheck.edition, ok: true),
      InspectionItem(check: InspectionCheck.mold, ok: true),
      InspectionItem(check: InspectionCheck.notes, ok: false),
      InspectionItem(
        check: InspectionCheck.signature,
        ok: false,
        note: 'chưa xác thực',
      ),
    ];
    final lots = [
      (
        id: 'a1',
        book: const Book(
          id: 'lb1',
          title: 'Gió đầu mùa',
          author: 'Thạch Lam',
          condition: BookCondition.veryGood,
          price: 1200000,
          sellerName: 'Kho ReBook',
          imageUrl: 'https://picsum.photos/seed/giodaumua/400/600',
        ),
        session: 'Phiên Tự Lực văn đoàn',
        edition: 'Đời Nay, 1937',
        no: 5,
        count: 20,
        estimate: (1500000, 2500000),
        start: 800000,
        reserve: 1300000,
        opensIn: const Duration(minutes: -4),
        price: 1200000,
      ),
      (
        id: 'a2',
        book: const Book(
          id: 'lb2',
          title: 'Vang bóng một thời',
          author: 'Nguyễn Tuân',
          condition: BookCondition.veryGood,
          price: 1500000,
          sellerName: 'Kho ReBook',
          imageUrl: 'https://picsum.photos/seed/vangbong/400/600',
        ),
        session: 'Sách quý trước 1975',
        edition: 'Tân Dân, Hà Nội · 1940 · bản in lần đầu',
        no: 7,
        count: 24,
        estimate: (3000000, 4500000),
        start: 1500000,
        reserve: 2800000,
        opensIn: const Duration(days: 2, hours: 4, minutes: 12),
        price: 1500000,
      ),
      (
        id: 'a3',
        book: const Book(
          id: 'lb3',
          title: 'Việt Nam sử lược',
          author: 'Trần Trọng Kim',
          condition: BookCondition.good,
          price: 1000000,
          sellerName: 'Kho ReBook',
          imageUrl: 'https://picsum.photos/seed/suluoc/400/600',
        ),
        session: 'Sách quý trước 1975',
        edition: 'Tân Việt · 1951',
        no: 12,
        count: 24,
        estimate: (2000000, 3000000),
        start: 1000000,
        reserve: 1800000,
        opensIn: const Duration(days: 2, hours: 4, minutes: 20),
        price: 1000000,
      ),
      (
        id: 'a4',
        book: const Book(
          id: 'lb4',
          title: 'Thơ thơ',
          author: 'Xuân Diệu',
          condition: BookCondition.veryGood,
          price: 600000,
          sellerName: 'Kho ReBook',
          imageUrl: 'https://picsum.photos/seed/thotho/400/600',
        ),
        session: 'Từ điển & sách khảo cứu',
        edition: 'Đời Nay · 1938',
        no: 15,
        count: 18,
        estimate: (1000000, 2000000),
        start: 600000,
        reserve: 900000,
        opensIn: const Duration(days: 9),
        price: 600000,
      ),
    ];

    for (final l in lots) {
      final opensAt = now.add(l.opensIn);
      final live = l.id == 'a1';
      _reserves[l.id] = l.reserve;
      _auctions[l.id] = Auction(
        id: l.id,
        book: l.book,
        currentPrice: l.price,
        minIncrement: increment(l.price),
        endsAt: live
            ? now.add(const Duration(seconds: 42))
            : opensAt.add(const Duration(seconds: 60)),
        opensAt: live ? null : opensAt,
        bidCount: live ? 4 : 0,
        highestBidder: live ? '#012' : null,
        lotNumber: l.no,
        lotCount: l.count,
        sessionTitle: l.session,
        edition: l.edition,
        estimateLow: l.estimate.$1,
        estimateHigh: l.estimate.$2,
        viewerCount: live ? 38 : null,
        bidLimit: 5000000,
        reserveMet: live ? l.price >= l.reserve : null,
        recentBids: live
            ? [
                BidEntry(paddle: '#012', amount: 1200000, at: now),
                BidEntry(
                  paddle: fakeMyPaddle,
                  amount: 1100000,
                  at: now.subtract(const Duration(seconds: 8)),
                  isYou: true,
                ),
                BidEntry(
                  paddle: '#027',
                  amount: 1000000,
                  at: now.subtract(const Duration(seconds: 15)),
                  auto: true,
                ),
                BidEntry(
                  paddle: '#012',
                  amount: 950000,
                  at: now.subtract(const Duration(seconds: 20)),
                ),
              ]
            : const [],
      );
      _lots[l.id] = LotDetail(
        id: l.id,
        book: l.book,
        startPrice: l.start,
        minIncrement: increment(l.start),
        opensAt: live ? now.subtract(const Duration(minutes: 4)) : opensAt,
        lotNumber: l.no,
        lotCount: l.count,
        sessionTitle: l.session,
        edition: l.edition,
        estimateLow: l.estimate.$1,
        estimateHigh: l.estimate.$2,
        deposit: 500000,
        bidLimit: 5000000,
        lotDurationSeconds: 60,
        softCloseSeconds: 15,
        inspector: 'Nguyễn Văn Kho',
        inspectedAt: now.subtract(const Duration(days: 4)),
        inspection: checklistGood,
        conditionReport:
            'Bìa ố vàng mép, sờn góc dưới. Gáy nguyên, khâu chỉ còn chắc. '
            'Trang lót có chữ ký chủ cũ.',
        isLive: live,
      );
    }
  }

  @override
  Future<List<Auction>> listAuctions() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _auctions.values.toList();
  }

  @override
  Stream<Auction> watchAuction(String id) async* {
    final initial = _auctions[id];
    if (initial == null) throw const ServerException(404, 'Auction not found');
    yield initial;

    Timer? bot;
    if (simulateOtherBidders) {
      bot = Timer.periodic(const Duration(seconds: 6), (_) {
        final a = _auctions[id]!;
        if (!a.isLiveAt(_now()) || a.nextMinBid > rivalCap) return;
        if (!a.youAreLeading && _random.nextBool()) return;
        _apply(a, a.nextMinBid, _rivals[_random.nextInt(_rivals.length)]);
      });
    }
    try {
      yield* _changes.stream.where((a) => a.id == id);
    } finally {
      bot?.cancel();
    }
  }

  @override
  Future<Auction> placeBid(String id, int amount) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final a = _get(id);
    if (!a.isLiveAt(_now())) {
      throw const ServerException(409, 'Lot is not open');
    }
    if (a.youAreLeading) throw const ServerException(409, 'Already leading');
    if (amount < a.nextMinBid) {
      throw const ServerException(409, 'Price changed');
    }
    if (a.exceedsLimit(amount)) {
      throw const ServerException(400, 'Bid limit exceeded');
    }
    return _apply(a, amount, fakeMyPaddle);
  }

  @override
  Future<LotDetail> getLot(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final lot = _lots[id];
    if (lot == null) throw const ServerException(404, 'Lot not found');
    return lot;
  }

  @override
  Future<bool> setFollowing(String id, {required bool following}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final lot = _lots[id];
    if (lot == null) throw const ServerException(404, 'Lot not found');
    _lots[id] = lot.copyWith(following: following);
    return following;
  }

  @override
  Future<LotDetail> register(String lotId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final lot = _lots[lotId];
    if (lot == null) throw const ServerException(404, 'Lot not found');
    if (lot.registered) throw const ServerException(409, 'Already registered');
    // Mọi lô cùng phiên coi như đã đăng ký.
    for (final e in _lots.entries.toList()) {
      if (e.value.sessionTitle == lot.sessionTitle) {
        _lots[e.key] = e.value.copyWith(registered: true);
      }
    }
    return _lots[lotId]!;
  }

  @override
  Future<Auction> setProxy(String id, int? maxAmount) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final a = _get(id);
    if (maxAmount != null && a.exceedsLimit(maxAmount)) {
      throw const ServerException(400, 'Bid limit exceeded');
    }
    final updated = a.copyWith(proxyMax: maxAmount);
    _auctions[id] = updated;
    _changes.add(updated);
    // Đang bị vượt giá mà vừa bật giá tối đa → trả hộ ngay.
    if (maxAmount != null &&
        !updated.youAreLeading &&
        updated.isLiveAt(_now()) &&
        updated.nextMinBid <= maxAmount) {
      return _apply(updated, updated.nextMinBid, fakeMyPaddle, auto: true);
    }
    return updated;
  }

  Auction _get(String id) {
    final a = _auctions[id];
    if (a == null) throw const ServerException(404, 'Auction not found');
    return a;
  }

  Auction _apply(Auction a, int amount, String paddle, {bool auto = false}) {
    final now = _now();
    final isYou = paddle == fakeMyPaddle;
    final late = a.endsAt.difference(now) < _softClose;
    var updated = a.copyWith(
      currentPrice: amount,
      minIncrement: increment(amount),
      bidCount: a.bidCount + 1,
      highestBidder: paddle,
      youAreLeading: isYou,
      endsAt: late ? now.add(_softClose) : a.endsAt,
      softCloseExtended: late,
      reserveMet: amount >= (_reserves[a.id] ?? 0),
      recentBids: [
        BidEntry(
          paddle: paddle,
          amount: amount,
          at: now,
          isYou: isYou,
          auto: auto,
        ),
        ...a.recentBids,
      ].take(8).toList(),
    );
    _auctions[a.id] = updated;
    _changes.add(updated);

    // Người khác vừa vượt giá và bạn đã bật giá tối đa → hệ thống trả hộ.
    final proxy = updated.proxyMax;
    if (!isYou && proxy != null && updated.nextMinBid <= proxy) {
      updated = _apply(updated, updated.nextMinBid, fakeMyPaddle, auto: true);
    }
    return updated;
  }
}
