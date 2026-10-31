import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

/// Phiên đấu giá trực tiếp (SRS 5.3–5.5, 6.5, 10.3).
abstract interface class AuctionRepository {
  Future<List<AuctionSession>> sessions({SessionStatus? status});

  Future<(AuctionSession, List<Lot>)> catalogue(String sessionId);

  Future<Lot> lot(String lotId);

  Future<List<Bid>> lotBids(String lotId);

  /// null nếu chưa đăng ký phiên.
  Future<Registration?> myRegistration(String sessionId);

  Future<List<Registration>> myRegistrations();

  /// Đồng ý quy chế + khóa cọc trong ví → nhận số bài. Gọi lại với cọc lớn hơn để tăng hạn mức.
  Future<Registration> register(String sessionId, int deposit);

  Future<Lot> watch(String lotId, {required bool on});

  /// Phiên tôi theo dõi (phiên yêu thích) và bật / tắt theo dõi cả phiên.
  Future<List<AuctionSession>> watchedSessions();

  Future<void> watchSession(String sessionId, {required bool on});

  /// Trả giá tự động tới [maxAmount].
  Future<void> setProxyBid(String lotId, int maxAmount);

  Future<Bid> placeBid(String lotId, int amount);

  /// Ảnh chụp trạng thái — gọi khi vào phòng và mỗi lần kết nối lại.
  Future<SessionState> sessionState(String sessionId);

  /// Sự kiện realtime của phiên. Sự kiện lạ (backend thêm loại mới) bị bỏ qua.
  Stream<AuctionEvent> events(String sessionId);

  /// Phát mỗi lần kết nối realtime được thiết lập lại.
  Stream<void> get reconnects;

  Future<SessionResult> results(String sessionId);

  Future<Wallet> wallet();

  /// Lời mời mua lần hai (SRS 6.6).
  Future<List<SecondChanceOffer>> secondChanceOffers();

  /// Nhận mua với giá đã trả → hoá đơn lô (đơn đấu giá).
  Future<Order> acceptSecondChance(String id);

  Future<SecondChanceOffer> declineSecondChance(String id);
}
