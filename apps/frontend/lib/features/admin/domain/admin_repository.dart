import 'package:book_marketplace/features/admin/domain/admin_report.dart';
import 'package:book_marketplace/features/admin/domain/cod_pending.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Quản trị sàn (SRS 2, 5.3, 7.2, 8, 11).
abstract interface class AdminRepository {
  Future<Dashboard> dashboard();

  /// Báo cáo trong khoảng ngày [from]–[to] (cả hai đầu): doanh thu theo ngày, cơ cấu thể loại và trạng thái đơn.
  Future<AdminReport> report(DateTime from, DateTime to);

  // Tin đăng
  Future<List<Listing>> listings({ListingStatus? status});
  Future<Listing> reviewListing(
    String id, {
    required bool approve,
    String? reason,
  });

  // Người dùng
  Future<List<AppUser>> users({String? q});
  Future<AppUser> setLocked(String id, {required bool locked, String? reason});

  /// Đổi vai trò (người dùng / nhân viên / quản trị).
  Future<AppUser> setRole(String id, UserRole role);

  /// Ghi nợ chargeback: ngân hàng / cổng thanh toán đòi lại tiền nạp. Thu ngay phần ví đang có, phần còn lại là nợ
  /// (chặn rút tiền và đấu giá).
  Future<void> chargeback(String userId, int amount, String reason);

  /// Gỡ lệnh cấm đấu giá (sau khi bị phạt bỏ thanh toán nhiều lần).
  Future<AppUser> liftAuctionBan(String id);

  // Danh mục
  Future<List<Category>> categories();
  Future<Category> saveCategory(String? id, String name, String? parentId);
  Future<void> deleteCategory(String id);

  // Phiên đấu giá
  Future<List<AuctionSession>> sessions();
  Future<(AuctionSession, List<Lot>)> session(String id);
  Future<AuctionSession> saveSession(String? id, AuctionSession draft);
  Future<(AuctionSession, List<Lot>)> setLots(String id, List<String> lotIds);
  Future<AuctionSession> publish(String id);

  /// Mở phiên ngay (chỉ môi trường demo; bình thường phiên tự mở đúng giờ).
  Future<AuctionSession> startNow(String id);

  /// Huỷ phiên chưa diễn ra; hoàn cọc cho người đã đăng ký.
  Future<AuctionSession> cancelSession(String id, String reason);
  Future<AuctionSession> pause(String id);
  Future<AuctionSession> resume(String id);
  Future<List<Lot>> lots({LotStatus? status});
  Future<Lot> cancelLot(String id, String reason);
  Future<SessionState> sessionState(String id);

  // Cấu hình, tiền
  Future<SystemConfig> config();
  Future<SystemConfig> updateConfig(SystemConfig config);
  Future<List<Withdrawal>> withdrawals();

  /// Duyệt rút tiền kèm biên lai chuyển khoản (SRS 8.1).
  Future<Withdrawal> completeWithdrawal(String id, WithdrawalReceipt receipt);

  /// Nhật ký hoạt động của Admin, mới nhất trước (SRS 8.1).
  Future<List<ActivityLog>> activityLogs();
  Future<List<Order>> disputes();

  /// Các yêu cầu trả hàng đã phân xử, kèm Admin phân xử và thời điểm.
  Future<List<Order>> resolvedDisputes();
  Future<Order> resolveDispute(String id, {required bool refund, String? note});

  /// Đơn COD đã giao nhưng sàn chưa nhận tiền đối soát.
  Future<List<CodPending>> codPending();

  /// Xác nhận sàn đã nhận đúng số tiền COD; sau đó tiền mới về shop (hoặc hoàn người mua).
  Future<void> remitCod(String orderId, int amount);
}
