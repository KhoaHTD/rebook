/// Nợ phạt bỏ thanh toán lô thắng hoặc phí lưu kho chưa thu đủ.
enum DebtKind { auctionPenalty, storageFee }

class Debt {
  const Debt({
    required this.id,
    required this.kind,
    required this.amount,
    required this.remaining,
    this.note,
    this.createdAt,
  });

  final String id;
  final DebtKind kind;
  final int amount;
  final int remaining;
  final String? note;
  final DateTime? createdAt;
}

/// Kết quả thu nợ từ số dư ví.
class DebtCollectResult {
  const DebtCollectResult({required this.collected, required this.stillOwed});

  final int collected;
  final int stillOwed;
}
