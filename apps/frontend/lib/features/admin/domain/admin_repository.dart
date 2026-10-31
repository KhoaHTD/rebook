import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Quản trị sàn (SRS 2, 5.3, 7.2, 8, 11).
abstract interface class AdminRepository {
  Future<Dashboard> dashboard();

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
}
