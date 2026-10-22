import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Giỏ hàng nhiều shop, đặt hàng và kết quả thanh toán (SRS 4.2, 8.1).
abstract interface class CartRepository {
  /// Phí ship tính theo [addressId] (mặc định: địa chỉ mặc định).
  Future<Cart> cart({String? addressId});

  Future<Cart> updateItem(String itemId, int quantity);

  Future<Cart> removeItem(String itemId);

  Future<List<Address>> addresses();

  Future<Wallet> wallet();

  /// Tách mỗi shop một đơn. [itemIds] null = cả giỏ.
  Future<CheckoutResult> checkout({
    required String addressId,
    required PaymentMethod method,
    List<String>? itemIds,
  });

  Future<Payment> payment(String id);

  /// Chỉ chế độ mock: giả lập cổng VNPay báo kết quả về backend.
  Future<Payment> simulateGateway(String paymentId, {required bool success});
}
