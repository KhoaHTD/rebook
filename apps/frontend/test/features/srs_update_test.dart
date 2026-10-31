import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/admin/data/fake_admin_repository.dart';
import 'package:book_marketplace/features/auction/data/fake_auction_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

/// Phần SRS cập nhật 31/10: hạn trả lời trả hàng, rút yêu cầu trả hàng, biên lai rút tiền, nhật ký Admin,
/// mời mua lần hai.
void main() {
  late FakeStore store;
  tearDown(() => store.dispose());

  String deliveredOrderId() => store
      .myOrders()
      .items
      .firstWhere((o) => o.status == OrderStatus.delivered)
      .id;

  group('trả hàng', () {
    setUp(() => store = FakeStore()..login('minhanh@rebook.vn', '123456'));

    test('yêu cầu trả hàng có hạn trả lời theo cấu hình (mặc định 2 ngày)', () {
      final id = deliveredOrderId();
      final before = DateTime.now();
      final o = store.requestReturn(id, 'Thiếu trang', const []);
      final respondBy = o.returnRequest!.respondBy!;
      expect(store.config.returnResponseDays, 2);
      expect(respondBy.difference(before).inHours, inInclusiveRange(47, 48));
    });

    test('quá hạn shop chưa trả lời → tự chuyển Admin phân xử', () {
      store.config = store.config.copyWith(returnResponseDays: 0);
      final id = deliveredOrderId();
      store.requestReturn(id, 'Sai ấn bản', const []);
      expect(store.order(id).returnRequest!.status, ReturnStatus.escalated);
      expect(store.disputes().map((o) => o.id), contains(id));
    });

    test(
      'bấm "Đã nhận hàng" khi đang yêu cầu trả = rút yêu cầu, đơn hoàn tất',
      () {
        final id = deliveredOrderId();
        store.requestReturn(id, 'Đổi ý', const []);
        final o = store.confirmReceived(id);
        expect(o.status, OrderStatus.completed);
        expect(o.returnRequest!.status, ReturnStatus.withdrawn);
      },
    );
  });

  group('rút tiền và nhật ký Admin', () {
    late FakeAdminRepository admin;
    setUp(() {
      store = FakeStore()..login('admin@rebook.vn', '123456');
      admin = FakeAdminRepository(store);
    });

    WithdrawalReceipt receipt(int amount) => WithdrawalReceipt(
      senderName: 'CTY REBOOK',
      transferredAt: DateTime.now(),
      amount: amount,
      proofImageUrl: 'mem://proof',
    );

    test('số tiền trên biên lai phải đúng số yêu cầu', () async {
      final w = (await admin.withdrawals()).firstWhere(
        (w) => w.status == WithdrawalStatus.pending,
      );
      await expectLater(
        admin.completeWithdrawal(w.id, receipt(w.amount + 1)),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            ErrorCodes.receiptMismatch,
          ),
        ),
      );
    });

    test(
      'duyệt kèm biên lai → hoàn tất, lưu biên lai và ghi nhật ký',
      () async {
        final w = (await admin.withdrawals()).firstWhere(
          (w) => w.status == WithdrawalStatus.pending,
        );
        final done = await admin.completeWithdrawal(w.id, receipt(w.amount));
        expect(done.status, WithdrawalStatus.completed);
        expect(done.receipt!.senderName, 'CTY REBOOK');
        final logs = await admin.activityLogs();
        expect(logs.first.action, AdminAction.withdrawalCompleted);
        expect(logs.first.adminName, 'Admin ReBook');
      },
    );

    test('đã duyệt rồi thì không duyệt lại được', () async {
      final done = (await admin.withdrawals()).firstWhere(
        (w) => w.status == WithdrawalStatus.completed,
      );
      await expectLater(
        admin.completeWithdrawal(done.id, receipt(done.amount)),
        throwsA(anything),
      );
    });

    test('khóa tài khoản và đổi cấu hình đều vào nhật ký', () async {
      final users = await admin.users(q: 'khoa');
      await admin.setLocked(users.single.id, locked: true);
      await admin.updateConfig(
        (await admin.config()).copyWith(auctionBanDays: 30),
      );
      final actions = (await admin.activityLogs()).take(2).map((l) => l.action);
      expect(
        actions,
        containsAll([AdminAction.userLocked, AdminAction.configChanged]),
      );
    });
  });

  group('mời mua lần hai', () {
    late FakeAuctionRepository repo;
    setUp(() {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      repo = FakeAuctionRepository(store);
    });

    test('có lời mời đang chờ, hạn 24h', () async {
      final offers = await repo.secondChanceOffers();
      expect(offers.single.status, SecondChanceStatus.pending);
      expect(offers.single.expiresAt.isAfter(DateTime.now()), isTrue);
    });

    test('nhận mua → hoá đơn đấu giá giá đã trả + phí người mua', () async {
      final offer = (await repo.secondChanceOffers()).single;
      final order = await repo.acceptSecondChance(offer.id);
      expect(order.type, OrderType.auction);
      expect(order.subtotal, offer.amount);
      expect(order.total, offer.amount + order.buyerPremium);
      expect(
        (await repo.secondChanceOffers()).single.status,
        SecondChanceStatus.accepted,
      );
      await expectLater(repo.acceptSecondChance(offer.id), throwsA(anything));
    });

    test('từ chối → trạng thái đã từ chối', () async {
      final offer = (await repo.secondChanceOffers()).single;
      final declined = await repo.declineSecondChance(offer.id);
      expect(declined.status, SecondChanceStatus.declined);
    });
  });
}
