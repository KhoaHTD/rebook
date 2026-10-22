import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auction/data/auction_repository_provider.dart';
import 'package:book_marketplace/features/auction/data/fake_auction_repository.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';

void main() {
  late ProviderContainer container;
  late FakeAuctionRepository repo;

  setUp(() {
    repo = FakeAuctionRepository(simulateOtherBidders: false);
    container = ProviderContainer(
      overrides: [auctionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('trả giá hợp lệ cập nhật phiên và phát qua stream', () async {
    final room = container.listen(auctionRoomProvider('a1'), (_, _) {});
    final before = await container.read(auctionRoomProvider('a1').future);

    container.listen(bidControllerProvider('a1'), (_, _) {});
    final ok = await container
        .read(bidControllerProvider('a1').notifier)
        .placeBid(before.nextMinBid);

    expect(ok, isTrue);
    await Future<void>.delayed(Duration.zero);
    final after = room.read().requireValue;
    expect(after.currentPrice, before.nextMinBid);
    expect(after.bidCount, before.bidCount + 1);
    expect(after.youAreLeading, isTrue);
    expect(after.recentBids.first.isYou, isTrue);
  });

  test('trả giá thấp hơn mức tối thiểu trả về lỗi', () async {
    container.listen(bidControllerProvider('a1'), (_, _) {});
    final ok = await container
        .read(bidControllerProvider('a1').notifier)
        .placeBid(1);

    expect(ok, isFalse);
    expect(
      container.read(bidControllerProvider('a1')).error,
      isA<ServerException>(),
    );
  });
}
