import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/consignment/data/fake_consignment_repository.dart';
import 'package:book_marketplace/features/seller/data/fake_seller_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

const _draft = BookDraft(
  title: 'Vang bóng một thời',
  author: 'Nguyễn Tuân',
  condition: ConditionGrade.good,
  imageUrls: ['a', 'b', 'c'],
  categoryId: 'c1',
);

void main() {
  late FakeStore store;
  tearDown(() => store.dispose());

  group('seller', () {
    test('mở shop rồi đăng tin → chờ duyệt (shop mới chưa uy tín)', () async {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      final repo = FakeSellerRepository(store);
      expect(await repo.myShop(), isNull);
      await repo.openShop(
        const ShopDraft(
          name: 'Kệ của Khoa',
          pickupAddress: 'Q.1, TP.HCM',
          bankName: 'VCB',
          bankAccount: '0123',
          bankHolder: 'HUYNH DANG KHOA',
        ),
      );
      final l = await repo.saveListing(null, _draft, price: 90000, stock: 1);
      expect(l.status, ListingStatus.pendingReview);
      expect(await repo.myListings(), hasLength(1));
    });

    test('ẩn / hiện tin và luồng đơn: xác nhận → giao → đã giao', () async {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      // Khoa mua một cuốn của shop Minh Anh.
      final l = store
          .searchListings(const ListingQuery(shopId: 's1'))
          .items
          .first;
      store.addToCart(l.id, 1);
      final orderId = store
          .checkout(
            addressId: store.myAddresses().first.id,
            method: PaymentMethod.cod,
          )
          .orders
          .single
          .id;

      store.login('minhanh@rebook.vn', '123456');
      final repo = FakeSellerRepository(store);
      expect((await repo.confirm(orderId)).status, OrderStatus.preparing);
      expect(
        (await repo.ship(orderId, trackingCode: 'GHN1')).status,
        OrderStatus.shipping,
      );
      expect((await repo.markDelivered(orderId)).status, OrderStatus.delivered);

      final hidden = await repo.setVisible(l.id, visible: false);
      expect(hidden.status, ListingStatus.hidden);
    });
  });

  group('consignment', () {
    test('giá mong muốn dưới 300k bị từ chối sơ duyệt ngay', () async {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      final c = await FakeConsignmentRepository(store)
          .create(_draft, 150000, 'Sách của ông nội');
      expect(c.status, ConsignmentStatus.preRejected);
    });

    test('sơ duyệt đạt → đặt lịch → có mã lịch hẹn', () async {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      final repo = FakeConsignmentRepository(store);
      final c = await repo.create(_draft, 800000, 'Bản in 1940');
      expect(c.status, ConsignmentStatus.submitted);
      store.preReview(c.id, approve: true);
      final slot = (await repo.slots(c.id)).firstWhere((s) => s.available);
      final booked = await repo.bookAppointment(c.id, slot.startAt);
      expect(booked.status, ConsignmentStatus.appointmentBooked);
      expect(booked.appointmentCode, startsWith('KG-'));
    });

    test('đề nghị giá sàn cao hơn mức thấp của ước tính → lỗi', () async {
      store = FakeStore()..login('minhanh@rebook.vn', '123456');
      final repo = FakeConsignmentRepository(store);
      final inspected = (await repo.mine()).where(
        (c) => c.status == ConsignmentStatus.inspected,
      );
      if (inspected.isEmpty) return;
      final c = inspected.first;
      final low = c.inspection!.estimateLow!;
      await expectLater(
        repo.decide(c.id, SellerDecision.counter, counterReserve: low + 1),
        throwsA(anything),
      );
      final ok = await repo.decide(
        c.id,
        SellerDecision.counter,
        counterReserve: low,
      );
      expect(ok.status, ConsignmentStatus.accepted);
      expect(ok.lotId, isNotNull);
    });
  });
}
