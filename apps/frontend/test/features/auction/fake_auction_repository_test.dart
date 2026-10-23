import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auction/data/fake_auction_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/rules.dart';

void main() {
  late FakeStore store;
  late FakeAuctionRepository repo;

  setUp(() {
    store = FakeStore()..login('minhanh@rebook.vn', '123456');
    repo = FakeAuctionRepository(store);
  });
  tearDown(() => store.dispose());

  test('phiên LIVE mẫu có lô đang chạy và người dùng đã có số bài', () async {
    final live = await repo.sessions(status: SessionStatus.live);
    expect(live, isNotEmpty);
    final state = await repo.sessionState(live.first.id);
    expect(state.currentLot, isNotNull);
    expect(state.myRegistration?.paddleNumber, isNotEmpty);
  });

  test('trả giá đúng bước → BidPlaced, giá cũ → PRICE_CHANGED', () async {
    final live = (await repo.sessions(status: SessionStatus.live)).first;
    final s = await repo.sessionState(live.id);
    final lot = s.currentLot!;
    if (lot.leadingPaddle == s.myRegistration!.paddleNumber) return;
    final next = nextBidAmount(
      currentPrice: lot.currentPrice,
      bidCount: lot.bidCount,
    );
    final events = repo.events(live.id);
    final first = events.first;
    final bid = await repo.placeBid(lot.id, next);
    expect(bid.amount, next);
    expect(await first, isNotNull);

    await expectLater(
      repo.placeBid(lot.id, next),
      throwsA(isA<ServerException>()),
    );
  });

  test('đăng ký phiên sắp tới khóa cọc trong ví', () async {
    final upcoming = (await repo.sessions(status: SessionStatus.published))
        .first;
    final before = await repo.wallet();
    final reg = await repo.register(upcoming.id, upcoming.depositAmount);
    expect(reg.bidLimit, upcoming.depositAmount * 10);
    final after = await repo.wallet();
    expect(after.available, before.available - upcoming.depositAmount);
    expect(after.held, before.held + upcoming.depositAmount);
  });
}
