import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/features/auction/data/auction_mapper.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/shared/domain/book.dart';

void main() {
  final session = api.SessionDetail(
    session: api.SessionSummary(
      id: 1,
      title: 'Sách cổ Việt Nam trước 1975',
      lotCount: 3,
      depositAmount: 500000,
      startAt: DateTime.now().add(const Duration(days: 2)),
    ),
    lotDurationSec: 60,
    softCloseSec: 15,
    myRegistration: const api.RegistrationResponse(
      paddle: '#001',
      bidLimit: 5000000,
      status: api.RegistrationStatus.approved,
    ),
  );

  test('LotLive → Auction: nhận ra người dùng đang dẫn đầu qua số bài', () {
    final ctx = RoomContext(session: session, me: session.myRegistration);
    final live = api.LotLive(
      id: 2,
      lotNumber: 1,
      title: 'Lều Chõng',
      status: api.LotStatus.open,
      startPrice: 500000,
      currentPrice: 600000,
      nextMinBid: 650000,
      increment: 50000,
      bidCount: 2,
      endsAt: DateTime.now().add(const Duration(seconds: 30)),
      leadingPaddle: '#001',
      recentBids: [
        api.BidView(paddle: '#001', amount: 600000, at: DateTime.now()),
        api.BidView(
          paddle: '#002',
          amount: 500000,
          at: DateTime.now(),
          auto: true,
        ),
      ],
    );

    final a = live.toAuction(ctx);
    expect(a.id, '2');
    expect(a.currentPrice, 600000);
    expect(a.nextMinBid, 650000);
    expect(a.youAreLeading, isTrue);
    expect(a.recentBids.first.isYou, isTrue);
    expect(a.recentBids.last.auto, isTrue);
    expect(a.bidLimit, 5000000);
    expect(a.lotCount, 3);
  });

  test('đồng hồ bị đẩy lùi → đánh dấu soft close', () {
    final ctx = RoomContext(session: session, me: session.myRegistration);
    final t0 = DateTime.now().add(const Duration(seconds: 5));
    api.LotLive at(DateTime end) => api.LotLive(
      id: 2,
      status: api.LotStatus.open,
      currentPrice: 600000,
      endsAt: end,
    );
    final before = at(t0).toAuction(ctx);
    final after = at(t0.add(const Duration(seconds: 10)))
        .toAuction(ctx, previous: before);
    expect(before.softCloseExtended, isFalse);
    expect(after.softCloseExtended, isTrue);
  });

  test('lô chưa có ai trả: giá tối thiểu là giá khởi điểm', () {
    const lot = api.LotPublic(
      id: 3,
      title: 'Vang Bóng Một Thời',
      status: api.LotStatus.scheduled,
      startPrice: 900000,
      conditionGrade: api.ConditionGrade.veryGood,
    );
    final a = lot.toAuction(session);
    expect(a.nextMinBid, 900000);
    expect(a.book.condition, BookCondition.veryGood);
    expect(a.opensAt, isNotNull);
  });

  test('catalogue lô: checklist kiểm định và trạng thái đăng ký', () {
    const detail = api.LotDetail(
      lot: api.LotPublic(
        id: 1,
        sessionId: 1,
        startPrice: 1500000,
        watching: true,
      ),
      book: api.BookResponse(
        title: 'Truyện Kiều',
        author: 'Nguyễn Du',
        publishYear: 1925,
      ),
      conditionReport: 'Đủ 180 trang.',
      checklist: {
        'fullPages': true,
        'editionVerified': true,
        'mold': false,
        'notes': true,
        'signature': 'chưa xác thực',
      },
    );
    final lot = detail.toDomain(session);
    expect(lot.registered, isTrue);
    expect(lot.following, isTrue);
    expect(lot.edition, '1925');
    expect(lot.deposit, 500000);
    expect(lot.inspection.map((i) => (i.check, i.ok)).toList(), [
      (InspectionCheck.fullPages, true),
      (InspectionCheck.edition, true),
      (InspectionCheck.mold, true),
      (InspectionCheck.notes, false),
      (InspectionCheck.signature, false),
    ]);
  });
}
