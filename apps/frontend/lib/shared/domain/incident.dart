enum IncidentType { lost, damaged }

enum IncidentStatus { pending, approved, rejected }

/// Sự cố kho (mất / hỏng sách): Staff khai báo, Admin duyệt và chi bồi thường từ ví sàn.
class WarehouseIncident {
  const WarehouseIncident({
    required this.id,
    required this.bookTitle,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.consignmentCode,
    this.sellerPercent,
    this.sellerAmount,
    this.buyerAmount,
    this.decisionNote,
  });

  final String id;
  final String bookTitle;
  final String? consignmentCode;
  final IncidentType type;
  final String description;
  final IncidentStatus status;
  final DateTime createdAt;

  /// Phần trăm bồi thường cho người bán (hỏng sách) và số tiền đã chi.
  final int? sellerPercent;
  final int? sellerAmount;
  final int? buyerAmount;
  final String? decisionNote;
}

/// Lô đã bán nhưng bị trả về kho, chờ Staff kiểm định lại.
class InspectingLot {
  const InspectingLot({
    required this.lotId,
    required this.bookTitle,
    this.consignmentCode,
    this.hammerPrice,
    this.closedAt,
  });

  final String lotId;
  final String bookTitle;
  final String? consignmentCode;
  final int? hammerPrice;
  final DateTime? closedAt;
}
