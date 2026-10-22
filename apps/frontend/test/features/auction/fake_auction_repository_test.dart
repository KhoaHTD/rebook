import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auction/data/fake_auction_repository.dart';

void main() {
  late FakeAuctionRepository repo;

  setUp(() => repo = FakeAuctionRepository(simulateOtherBidders: false));

  test('bước giá theo bậc', () {
    expect(FakeAuctionRepository.increment(150000), 10000);
    expect(FakeAuctionRepository.increment(500000), 50000);
    expect(FakeAuctionRepository.increment(1200000), 100000);
    expect(FakeAuctionRepository.increment(6000000), 500000);
  });

  test('không trả giá được khi đang dẫn đầu', () async {
    final a = (await repo.listAuctions()).firstWhere((x) => x.id == 'a1');
    await repo.placeBid('a1', a.nextMinBid);
    expect(
      () => repo.placeBid('a1', a.nextMinBid + 1000000),
      throwsA(isA<ServerException>()),
    );
  });

  test('vượt hạn mức trả giá bị từ chối', () async {
    expect(
      () => repo.placeBid('a1', 6000000),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'status', 400),
      ),
    );
  });

  test('lô chưa mở không nhận giá', () async {
    expect(
      () => repo.placeBid('a2', 2000000),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'status', 409),
      ),
    );
  });

  test('bật giá tối đa khi đang bị vượt → hệ thống trả hộ ngay', () async {
    final updated = await repo.setProxy('a1', 2000000);
    expect(updated.youAreLeading, isTrue);
    expect(updated.proxyMax, 2000000);
    expect(updated.recentBids.first.auto, isTrue);
  });

  test('trả giá ở giây cuối được cộng thêm thời gian (soft close)', () async {
    var now = DateTime(2026, 10, 22, 20);
    final late = FakeAuctionRepository(
      simulateOtherBidders: false,
      now: () => now,
    );
    // a1 hết hạn sau 42 giây; đi tới còn 5 giây
    now = now.add(const Duration(seconds: 37));
    final a = (await late.listAuctions()).firstWhere((x) => x.id == 'a1');
    final after = await late.placeBid('a1', a.nextMinBid);
    expect(after.softCloseExtended, isTrue);
    expect(after.endsAt, now.add(const Duration(seconds: 15)));
  });

  test('đăng ký đánh dấu mọi lô cùng phiên', () async {
    final lot = await repo.register('a2');
    expect(lot.registered, isTrue);
    expect((await repo.getLot('a3')).registered, isTrue);
    expect((await repo.getLot('a4')).registered, isFalse);
    expect(() => repo.register('a2'), throwsA(isA<ServerException>()));
  });

  test('theo dõi lô', () async {
    expect(await repo.setFollowing('a2', following: true), isTrue);
    expect((await repo.getLot('a2')).following, isTrue);
  });

  test('ước tính tổng tiền nếu thắng gồm 10% phí người mua', () async {
    final lot = await repo.getLot('a2');
    expect(lot.totalIfWon(3000000), 3300000);
  });
}
