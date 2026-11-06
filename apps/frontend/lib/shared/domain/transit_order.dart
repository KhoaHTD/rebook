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
