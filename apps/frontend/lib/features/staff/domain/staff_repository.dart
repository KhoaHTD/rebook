import 'package:book_marketplace/shared/domain/transit_order.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/incident.dart';

/// Nghiệp vụ nhân viên kho / kiểm định (SRS 6.1, 6.2, 6.6).
abstract interface class StaffRepository {
  Future<List<Consignment>> consignments({ConsignmentStatus? status});

  Future<Consignment> consignment(String id);

  /// Sơ duyệt online trong 48 giờ.
  Future<Consignment> preReview(
    String id, {
    required bool approve,
    String? reason,
  });

  Future<List<Consignment>> appointments();

  /// Nhận sách bằng mã lịch hẹn, lập biên nhận, gán kệ.
  Future<Consignment> checkIn(
    String code, {
    required List<String> receiptImageUrls,
    String? shelfCode,
  });

  Future<Consignment> submitInspection(String id, InspectionDraft draft);

  Future<List<WarehouseItem>> warehouse({WarehouseStatus? status});

  Future<WarehouseItem> updateWarehouse(
    String id, {
    String? shelfCode,
    WarehouseStatus? status,
  });

  /// Đơn lô đấu giá kho cần giao.
  Future<List<Order>> auctionOrders();

  /// Chuẩn bị → đang giao → đã giao.
  Future<Order> advanceOrder(String id, {String? trackingCode});

  /// Đơn thường đang giao, cũ nhất trước, để đối chiếu với hãng vận chuyển.
  Future<List<TransitOrder>> inTransit();

  /// Hãng báo đã giao thành công (đường chính để đơn COD đi tiếp).
  Future<void> carrierDelivered(String id);

  /// Hãng báo giao thất bại (người nhận từ chối, thất lạc…): hoàn tiền nếu đã trả trước.
  Future<void> carrierFailed(String id, String reason, DeliveryFaultKind fault);

  /// Đơn lô đấu giá: giao thất bại (kèm bên có lỗi), xử lý yêu cầu trả hàng, xác nhận kho nhận lại sách.
  Future<void> auctionDeliveryFailed(
    String id,
    String reason,
    DeliveryFaultKind fault,
  );

  Future<void> auctionReturnDecision(
    String id, {
    required bool accept,
    String? note,
  });

  Future<void> auctionReturnReceived(String id);

  /// Khai báo sự cố mất / hỏng sách trong kho; chờ Admin duyệt.
  Future<WarehouseIncident> reportIncident(
    String warehouseItemId,
    IncidentType type,
    String description,
  );

  Future<List<WarehouseIncident>> incidents();

  /// Admin duyệt sự cố: [sellerPercent] là phần bồi thường cho người bán (hỏng sách).
  Future<WarehouseIncident> approveIncident(
    String id, {
    int sellerPercent = 100,
  });

  Future<WarehouseIncident> rejectIncident(String id, String reason);

  /// Lô bị trả về kho sau khi bán, chờ kiểm định lại.
  Future<List<InspectingLot>> inspectingLots();

  /// Đạt → chờ xếp phiên; không đạt → trả người bán.
  Future<void> reinspect(
    String lotId, {
    required bool passed,
    required String report,
  });
}
