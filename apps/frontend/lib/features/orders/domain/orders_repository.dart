import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Đơn của người mua, gồm cả hóa đơn lô đấu giá đã thắng (SRS 4.4, 5.5, 7.3).
abstract interface class OrdersRepository {
  Future<List<Order>> myOrders();

  Future<Order> order(String id);

  /// Hủy ngay (chưa xác nhận) hoặc gửi yêu cầu hủy (đang chuẩn bị).
  Future<Order> cancel(String id, String reason);

  Future<Order> confirmReceived(String id);

  Future<Order> requestReturn(String id, String reason, List<String> imageUrls);

  Future<Order> review(String id, int rating, String? comment);

  /// Thanh toán lại đơn chờ thanh toán / hóa đơn đấu giá.
  Future<CheckoutResult> pay(
    String id,
    PaymentMethod method, {
    String? addressId,
    bool pickupAtWarehouse = false,
  });

  Future<List<Address>> addresses();

  Future<Wallet> wallet();
}
