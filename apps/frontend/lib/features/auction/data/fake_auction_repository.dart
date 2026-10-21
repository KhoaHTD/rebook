import 'dart:async';
import 'dart:math';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/features/auction/domain/auction_repository.dart';
import 'package:book_marketplace/shared/data/fake_books.dart';

/// Giả lập phiên đấu giá: thỉnh thoảng có "người khác" trả giá để thấy realtime.
class FakeAuctionRepository implements AuctionRepository {
  FakeAuctionRepository({this.simulateOtherBidders = true}) {
    final now = DateTime.now();
    for (final (i, book) in fakeBooks.take(4).indexed) {
      _auctions['a${i + 1}'] = Auction(
        id: 'a${i + 1}',
        book: book,
        currentPrice: book.price,
        minIncrement: 5000,
        endsAt: now.add(Duration(minutes: 3 + i * 7)),
        bidCount: i,
        highestBidder: i == 0 ? null : 'reader_$i',
      );
    }
  }

  final bool simulateOtherBidders;
  final _auctions = <String, Auction>{};
  final _changes = StreamController<Auction>.broadcast();
  final _random = Random();

  static const _otherBidders = [
    'mot_sach',
    'thu_vien_nho',
    'book_lover',
    'gac_sach_cu',
  ];

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
        if (a.isEndedAt(DateTime.now()) || _random.nextBool()) return;
        _apply(
          a,
          a.nextMinBid,
          _otherBidders[_random.nextInt(_otherBidders.length)],
        );
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
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final a = _auctions[id];
    if (a == null) throw const ServerException(404, 'Auction not found');
    if (a.isEndedAt(DateTime.now())) {
      throw const ServerException(409, 'Auction ended');
    }
    if (amount < a.nextMinBid) throw const ServerException(422, 'Bid too low');
    return _apply(a, amount, 'you');
  }

  Auction _apply(Auction a, int amount, String bidder) {
    final updated = a.copyWith(
      currentPrice: amount,
      bidCount: a.bidCount + 1,
      highestBidder: bidder,
    );
    _auctions[a.id] = updated;
    _changes.add(updated);
    return updated;
  }
}
