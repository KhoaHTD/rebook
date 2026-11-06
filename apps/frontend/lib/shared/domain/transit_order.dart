/// Đơn thường đang giao để Staff đối chiếu kết quả với hãng vận chuyển.
class TransitOrder {
  const TransitOrder({
    required this.id,
    required this.code,
    required this.shopName,
    required this.isCod,
    required this.total,
    this.trackingCode,
    this.shippedAt,
    this.overdue = false,
  });

  final String id;
  final String code;
  final String shopName;
  final bool isCod;
  final int total;
  final String? trackingCode;
  final DateTime? shippedAt;

  /// Giao quá lâu mà chưa có kết quả.
  final bool overdue;
}

/// Ai gây giao thất bại: quyết định ai chịu phí và tiền hoàn đi đâu.
enum DeliveryFaultKind {
  /// Người mua từ chối nhận, sai địa chỉ, không liên lạc được.
  buyer,

  /// Hãng vận chuyển làm thất lạc / hư hỏng.
  carrier,

  /// Shop gửi sai hoặc thiếu hàng.
  shop,
}
