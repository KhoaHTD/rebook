import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'commerce.freezed.dart';

@freezed
abstract class CartItem with _$CartItem {
  const factory CartItem({
    required String id,
    required Listing listing,
    required int quantity,
  }) = _CartItem;
}

/// Giỏ chia theo shop: mỗi shop giao riêng và có phí ship riêng (SRS 4.2).
@freezed
abstract class CartGroup with _$CartGroup {
  const factory CartGroup({
    required ShopSummary shop,
    required List<CartItem> items,
    required int subtotal,
    required int shippingFee,
  }) = _CartGroup;
}

@freezed
abstract class Cart with _$Cart {
  const Cart._();

  const factory Cart({
    required List<CartGroup> groups,
    required int subtotal,
    required int shippingTotal,
    required int total,
  }) = _Cart;

  static const empty = Cart(
    groups: [],
    subtotal: 0,
    shippingTotal: 0,
    total: 0,
  );

  int get itemCount =>
      groups.fold(0, (n, g) => n + g.items.fold(0, (m, i) => m + i.quantity));
}

@freezed
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String title,
    required int unitPrice,
    required int quantity,
    String? listingId,
    String? lotId,
    String? imageUrl,
  }) = _OrderItem;
}

@freezed
abstract class OrderStatusChange with _$OrderStatusChange {
  const factory OrderStatusChange({
    required OrderStatus to,
    required DateTime at,
    OrderStatus? from,
    String? note,
  }) = _OrderStatusChange;
}

@freezed
abstract class ReturnRequest with _$ReturnRequest {
  const factory ReturnRequest({
    required String id,
    required String reason,
    required List<String> imageUrls,
    required ReturnStatus status,
    String? resolution,

    /// Hạn shop / kho trả lời; quá hạn thì tự chuyển Admin phân xử (SRS 4.4).
    DateTime? respondBy,

    /// Admin phân xử và lúc nào (SRS 8.1: nhật ký).
    String? resolvedBy,
    DateTime? resolvedAt,
  }) = _ReturnRequest;
}

/// Đơn hàng — dùng chung cho mua thường và lô đã thắng (SRS 7.3).
@freezed
abstract class Order with _$Order {
  const Order._();

  const factory Order({
    required String id,
    required String code,
    required OrderType type,
    required OrderStatus status,
    required List<OrderItem> items,
    required int subtotal,
    required int shippingFee,
    required int buyerPremium,
    required int depositApplied,
    required int total,
    required DateTime createdAt,
    required List<OrderStatusChange> history,
    required bool canReview,
    ShopSummary? shop,
    String? buyerName,
    PaymentMethod? paymentMethod,
    Address? address,
    @Default(false) bool pickupAtWarehouse,
    String? trackingCode,
    DateTime? paymentDeadline,
    DateTime? confirmDeadline,
    DateTime? complaintDeadline,
    @Default(false) bool cancelRequested,
    Review? review,
    ReturnRequest? returnRequest,
  }) = _Order;

  /// Người mua tự hủy được khi đơn chưa được shop xác nhận (SRS 4.4).
  bool get buyerCanCancelDirectly =>
      status == OrderStatus.pendingPayment ||
      status == OrderStatus.pendingConfirm;

  bool get buyerCanRequestCancel =>
      status == OrderStatus.preparing && !cancelRequested;
}

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required String id,
    required int amount,
    required PaymentStatus status,
    String? paymentUrl,
    DateTime? expiresAt,
  }) = _Payment;
}

@freezed
abstract class CheckoutResult with _$CheckoutResult {
  const factory CheckoutResult({
    required List<Order> orders,
    Payment? payment,
  }) = _CheckoutResult;
}

/// Ví nội bộ: số dùng được và số đang bị khóa (cọc, tiền bán chờ hoàn tất) (SRS 8.1).
@freezed
abstract class Wallet with _$Wallet {
  const Wallet._();

  const factory Wallet({required int available, required int held}) = _Wallet;

  int get total => available + held;
}

@freezed
abstract class WalletTxn with _$WalletTxn {
  const factory WalletTxn({
    required String id,
    required WalletTxnType type,
    required int amount,
    required int balanceAfter,
    required DateTime createdAt,
    String? note,
    String? refType,
    String? refId,
  }) = _WalletTxn;
}

@freezed
abstract class Withdrawal with _$Withdrawal {
  const factory Withdrawal({
    required String id,
    required int amount,
    required WithdrawalStatus status,
    required DateTime createdAt,
    String? userName,

    /// Thông tin nhận tiền người bán nhập khi tạo yêu cầu.
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? note,

    /// Admin duyệt và lúc nào.
    String? approvedBy,
    DateTime? approvedAt,

    /// Biên lai chuyển khoản Admin nhập khi duyệt (SRS 8.1).
    WithdrawalReceipt? receipt,
  }) = _Withdrawal;
}

/// Tài khoản ngân hàng đã dùng để rút tiền (màn "Gần đây"); sao = yêu thích, đứng đầu danh sách.
@freezed
abstract class BankAccount with _$BankAccount {
  const factory BankAccount({
    required String id,
    required String bankName,
    required String accountNumber,
    required String accountName,
    required bool favorite,
    required DateTime lastUsedAt,
  }) = _BankAccount;
}

/// Biên lai chuyển khoản: người chuyển, thời điểm, số tiền (đúng số yêu cầu), ảnh chứng từ.
@freezed
abstract class WithdrawalReceipt with _$WithdrawalReceipt {
  const factory WithdrawalReceipt({
    required String senderName,
    required DateTime transferredAt,
    required int amount,
    required String proofImageUrl,
  }) = _WithdrawalReceipt;
}

/// Một dòng nhật ký hoạt động của Admin (SRS 8.1).
@freezed
abstract class ActivityLog with _$ActivityLog {
  const factory ActivityLog({
    required String id,
    required String adminName,
    required AdminAction action,
    required DateTime createdAt,
    String? target,
    String? note,
  }) = _ActivityLog;
}

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    required bool isRead,
    required DateTime createdAt,
    String? link,
  }) = _AppNotification;
}
