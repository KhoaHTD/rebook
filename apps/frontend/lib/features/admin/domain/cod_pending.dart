/// Đơn COD đã giao nhưng sàn chưa nhận tiền đối soát từ hãng vận chuyển.
class CodPending {
  const CodPending({
    required this.orderId,
    required this.code,
    required this.total,
    this.deliveredAt,
    this.refundPending = false,
  });

  final String orderId;
  final String code;
  final int total;
  final DateTime? deliveredAt;

  /// Đơn trả hàng đang chờ nhận tiền COD để hoàn cho người mua.
  final bool refundPending;
}
