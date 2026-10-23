import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/auction/domain/live_reducer.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

void main() {
  final t0 = DateTime(2026, 10, 22, 20);

  Lot lot(String id, {int price = 100000, int bids = 0, String? leader}) => Lot(
    id: id,
    sessionId: 's',
    lotNumber: 1,
    book: const Book(
      id: 'b',
      title: 'Số Đỏ',
      author: 'Vũ Trọng Phụng',
      condition: ConditionGrade.good,
    ),
    estimateLow: 100000,
    estimateHigh: 300000,
    startPrice: 100000,
    currentPrice: price,
    bidCount: bids,
    status: LotStatus.live,
    watched: false,
    leadingPaddle: leader,
    endsAt: t0.add(const Duration(seconds: 60)),
  );

  SessionState state({Registration? reg, Lot? current}) => SessionState(
    session: AuctionSession(
      id: 's',
      title: 'Phiên',
      startAt: t0,
      registrationDeadline: t0,
      minParticipants: 2,
      depositAmount: 500000,
      lotDurationSec: 60,
      softCloseSec: 15,
      status: SessionStatus.live,
      lotCount: 2,
      registeredCount: 5,
    ),
    lots: [lot('l1'), lot('l2')],
    serverTime: t0,
    recentBids: const [],
    currentLot: current ?? lot('l1'),
    myRegistration: reg,
  );

  const reg = Registration(
    id: 'r',
    sessionId: 's',
    sessionTitle: 'Phiên',
    paddleNumber: '027',
    depositAmount: 500000,
    bidLimit: 5000000,
    committedAmount: 0,
    status: RegistrationStatus.approved,
  );

  test('BidPlaced cập nhật giá, người dẫn và đầu danh sách diễn biến', () {
    final bid = Bid(
      id: 'x',
      lotId: 'l1',
      paddleNumber: '012',
      amount: 110000,
      createdAt: t0,
    );
    final next = applyAuctionEvent(
      state(),
      BidPlaced(t0, lot('l1', price: 110000, bids: 1, leader: '012'), bid),
    );
    expect(next.currentLot!.currentPrice, 110000);
    expect(next.recentBids.first.id, 'x');
    expect(next.lots.first.leadingPaddle, '012');
  });

  test('LotOpened chuyển sang lô mới và xoá diễn biến cũ', () {
    final next = applyAuctionEvent(state(), LotOpened(t0, lot('l2')));
    expect(next.currentLot!.id, 'l2');
    expect(next.session.currentLotId, 'l2');
    expect(next.recentBids, isEmpty);
  });

  test('SessionPaused / SessionEnded đổi trạng thái phiên', () {
    expect(
      applyAuctionEvent(state(), SessionPaused(t0)).session.status,
      SessionStatus.paused,
    );
    expect(
      applyAuctionEvent(state(), SessionEnded(t0)).session.status,
      SessionStatus.ended,
    );
  });

  group('bidBlockFor', () {
    test('chưa đăng ký', () {
      expect(bidBlockFor(state(), nextAmount: 100000), BidBlock.notRegistered);
    });
    test('đang dẫn đầu thì không tự trả đè', () {
      final s = state(
        reg: reg,
        current: lot('l1', bids: 1, leader: '027'),
      );
      expect(bidBlockFor(s, nextAmount: 110000), BidBlock.leading);
    });
    test('vượt hạn mức', () {
      expect(
        bidBlockFor(state(reg: reg), nextAmount: 6000000),
        BidBlock.overLimit,
      );
    });
    test('trả được', () {
      expect(bidBlockFor(state(reg: reg), nextAmount: 100000), BidBlock.none);
    });
  });
}
