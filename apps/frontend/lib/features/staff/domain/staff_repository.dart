import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

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
}
