import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/upload_service.dart';
import 'package:book_marketplace/core/utils/external_link.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nhật ký đổi khoá cấu hình thô sang tên hiển thị', () {
    const log = api.ActivityLogResponse(
      id: 1,
      action: 'UPDATE_CONFIG',
      summary: 'Đặt fee.fixed_price_percent = 7',
    );
    expect(log.toDomain()!.note, 'Đặt Phí bán giá cố định (%) = 7');
    const other = api.ActivityLogResponse(
      id: 2,
      action: 'UPDATE_CONFIG',
      summary: 'Đặt khoá.lạ = 1',
    );
    expect(other.toDomain()!.note, 'Đặt khoá.lạ = 1');
  });

  test('lịch sử đơn đổi tên enum thanh toán sang tên thường gọi', () {
    final order = api.OrderDetail(
      id: 1,
      history: [
        api.HistoryResponse(
          toStatus: api.OrderStatus.pendingConfirm,
          note: 'Đã thanh toán (WALLET)',
          createdAt: DateTime(2026, 11, 5),
        ),
        api.HistoryResponse(
          toStatus: api.OrderStatus.pendingPayment,
          note: 'Đặt hàng',
          createdAt: DateTime(2026, 11, 5),
        ),
      ],
    ).toDomain();
    expect(order.history.first.note, 'Đã thanh toán (Ví ReBook)');
    expect(order.history.last.note, 'Đặt hàng');
  });

  test('đơn hàng dùng bìa đóng gói sẵn thay cho ảnh giả của backend', () {
    const summary = api.OrderSummary(
      id: 1,
      firstItemTitle: 'Tắt Đèn',
      coverUrl: 'https://picsum.photos/seed/rebook-7-1/600/800',
      itemCount: 1,
    );
    expect(
      summary.toDomain().items.first.imageUrl,
      'assets/books/tat-den-0.jpg',
    );
    const item = api.OrderItemResponse(
      id: 1,
      title: 'Tắt Đèn',
      imageUrl: 'https://picsum.photos/seed/rebook-7-1/600/800',
    );
    expect(item.toDomain().imageUrl, 'assets/books/tat-den-0.jpg');
    const other = api.OrderItemResponse(
      id: 2,
      title: 'Sách lạ',
      imageUrl: 'https://example.com/a.jpg',
    );
    expect(other.toDomain().imageUrl, 'https://example.com/a.jpg');
  });

  const cart = api.CartResponse(
    shops: [
      api.CartShopGroup(
        shopId: 1,
        shopName: 'A',
        subtotal: 300000,
        items: [
          api.CartLine(listingId: 10, title: 'X', price: 100000, quantity: 1),
          api.CartLine(listingId: 11, title: 'Y', price: 100000, quantity: 2),
        ],
      ),
      api.CartShopGroup(
        shopId: 2,
        shopName: 'B',
        subtotal: 50000,
        items: [
          api.CartLine(listingId: 20, title: 'Z', price: 50000, quantity: 1),
        ],
      ),
    ],
    subtotal: 350000,
  );

  test(
    'giỏ hàng: chọn vài món thì chỉ tính các món đó, shop không còn món bị bỏ',
    () {
      final c = cartToDomain(
        cart,
        only: {'11'},
        quote: const api.CheckoutPreview(
          shops: [api.ShopQuote(shopId: 1, shippingFee: 20000)],
        ),
      );
      expect(c.groups, hasLength(1));
      expect(c.groups.single.items.single.id, '11');
      expect(c.subtotal, 200000);
      expect(c.shippingTotal, 20000);
      expect(c.total, 220000);
    },
  );

  test('giỏ hàng: không chọn thì giữ nguyên số của backend', () {
    final c = cartToDomain(cart);
    expect(c.groups, hasLength(2));
    expect(c.subtotal, 350000);
  });

  test('nhật ký admin: mã backend đổi sang enum, mã lạ bị bỏ qua', () {
    expect(adminActionToDomain('APPROVE_LISTING'), AdminAction.listingApproved);
    expect(
      adminActionToDomain('REJECT_WITHDRAWAL'),
      AdminAction.withdrawalRejected,
    );
    expect(adminActionToDomain('UPDATE_CONFIG'), AdminAction.configChanged);
    expect(
      const api.ActivityLogResponse(id: 1, action: 'SOMETHING_NEW').toDomain(),
      isNull,
    );
    final log = api.ActivityLogResponse(
      id: 5,
      adminName: 'Admin',
      action: 'LOCK_USER',
      summary: 'Khoá buyer1',
      createdAt: DateTime(2026, 11, 1),
    ).toDomain()!;
    expect(log.action, AdminAction.userLocked);
    expect(log.note, 'Khoá buyer1');
  });

  test('lời mời mua lần hai lấy từ hoá đơn lô có cờ secondChance', () {
    final due = DateTime.now().add(const Duration(hours: 5));
    final offer = api.OrderSummary(
      id: 7,
      lotId: 3,
      status: api.OrderStatus.pendingPayment,
      firstItemTitle: 'Truyện Kiều',
      total: 900000,
      paymentDueAt: due,
      secondChance: true,
    ).toSecondChance(lotNumber: 2);
    expect(offer.id, '7');
    expect(offer.lotId, '3');
    expect(offer.lotNumber, 2);
    expect(offer.amount, 900000);
    expect(offer.status, SecondChanceStatus.pending);

    final expired = api.OrderSummary(
      id: 8,
      status: api.OrderStatus.pendingPayment,
      paymentDueAt: DateTime.now().subtract(const Duration(minutes: 1)),
      secondChance: true,
    ).toSecondChance();
    expect(expired.status, SecondChanceStatus.expired);

    const declined = api.OrderSummary(
      id: 9,
      status: api.OrderStatus.cancelled,
      secondChance: true,
    );
    expect(declined.toSecondChance().status, SecondChanceStatus.declined);
  });

  test('rút tiền: thông tin ngân hàng, người duyệt và biên lai', () {
    final w = api.WithdrawResponse(
      id: 4,
      userName: 'Seller 1',
      amount: 500000,
      bankName: 'VCB',
      accountNumber: '0123',
      accountHolder: 'NGUYEN VAN A',
      status: api.WithdrawStatus.approved,
      note: 'Đã chuyển',
      userNote: 'Rut tien thang 11',
      processedByName: 'Admin',
      processedAt: DateTime(2026, 11, 2),
      createdAt: DateTime(2026, 11, 1),
      transfer: api.TransferReceipt(
        senderName: 'ReBook',
        transferTime: DateTime(2026, 11, 2, 9),
        amount: 500000,
        proofImageUrl: '/files/a.png',
      ),
    ).toDomain();
    expect(w.status, WithdrawalStatus.completed);
    expect(w.userName, 'Seller 1');
    expect(w.bankAccountNumber, '0123');
    expect(w.bankAccountName, 'NGUYEN VAN A');
    expect(w.approvedBy, 'Admin');
    expect(w.receipt?.amount, 500000);
    expect(w.receipt?.proofImageUrl, '/files/a.png');
    // Ghi chú hiển thị là của người rút, không phải ghi chú Admin khi xử lý.
    expect(w.note, 'Rut tien thang 11');
  });

  test('tin đăng mang tên Admin duyệt và thời điểm duyệt', () {
    final at = DateTime(2026, 11, 3, 10);
    final l = api.ListingSummary(
      id: 9,
      title: 'Sách',
      status: api.ListingStatus.rejected,
      reviewedBy: 1,
      reviewedByName: 'Admin Duyệt',
      reviewedAt: at,
    ).toDomain();
    expect(l.reviewedBy, 'Admin Duyệt');
    expect(l.reviewedAt, at);
    expect(const api.ListingSummary(id: 10).toDomain().reviewedBy, isNull);
  });

  test('ảnh upload lên backend (URL tương đối) được ghép với địa chỉ API', () {
    expect(resolveImageUrl('/files/a.png'), '${Env.apiBaseUrl}/files/a.png');
    expect(
      resolveImageUrl('https://example.com/b.jpg'),
      'https://example.com/b.jpg',
    );
    expect(resolveImageUrl('assets/books/x.jpg'), 'assets/books/x.jpg');
    expect(resolveImageUrl('mem://3'), 'mem://3');
  });

  test('địa chỉ: ghim bản đồ và loại địa chỉ đi cả hai chiều', () {
    const a = Address(
      id: '1',
      receiver: 'A',
      phone: '0900000000',
      province: 'Hà Nội',
      district: 'Ba Đình',
      ward: 'Kim Mã',
      detail: '1 Kim Mã',
      isDefault: true,
      latitude: 21.03,
      longitude: 105.82,
      type: AddressType.office,
    );
    final req = a.toRequest();
    expect(req.latitude, 21.03);
    expect(req.addressType, api.AddressType.office);

    const res = api.AddressResponse(
      id: 1,
      latitude: 21.03,
      longitude: 105.82,
      addressType: api.AddressType.office,
    );
    final back = res.toDomain();
    expect(back.hasPin, isTrue);
    expect(back.type, AddressType.office);
    expect(const api.AddressResponse(id: 2).toDomain().type, AddressType.home);
  });

  test('thanh toán: chỉ hiện cổng giả lập khi backend cho phép', () {
    const real = api.PaymentResponse(
      code: 'PM1',
      status: api.PaymentStatus.pending,
      paymentUrl: 'https://sandbox.zalopayment.vn/paymentv2/vpcpay.html?x=1',
      simulateAvailable: false,
    );
    expect(isMockUrl(real.toDomain().paymentUrl), isFalse);
    expect(real.toDomain().id, 'PM1');

    // Backend chưa cấu hình ZaloPay: giả lập.
    const sim = api.PaymentResponse(
      code: 'PM2',
      status: api.PaymentStatus.pending,
      simulateAvailable: true,
    );
    expect(isMockUrl(sim.toDomain().paymentUrl), isTrue);

    // Tra cứu lại thanh toán ZaloPay thật: không có link, cũng không phải giả lập.
    const lookup = api.PaymentResponse(
      code: 'PM3',
      status: api.PaymentStatus.pending,
      simulateAvailable: false,
    );
    expect(lookup.toDomain().paymentUrl, isNull);
    expect(isMockUrl(lookup.toDomain().paymentUrl), isFalse);
  });
}
