import 'package:book_marketplace/features/auction/domain/auction.dart';

abstract interface class AuctionRepository {
  Future<List<Auction>> listAuctions();

  /// Phát trạng thái hiện tại của phiên, rồi phát lại mỗi khi có bid mới (realtime).
  Stream<Auction> watchAuction(String id);

  /// Backend kiểm tra hợp lệ (giá tối thiểu, phiên còn mở...) và trả về trạng thái mới.
  Future<Auction> placeBid(String id, int amount);

  /// Catalogue lô: báo cáo kiểm định, giá ước tính, tiền cọc.
  Future<LotDetail> getLot(String id);

  /// Theo dõi lô để nhận nhắc trước phiên. Trả về trạng thái mới.
  Future<bool> setFollowing(String id, {required bool following});

  /// Đăng ký tham gia phiên chứa lô + khoá tiền cọc trong ví. Trả về catalogue đã cập nhật.
  Future<LotDetail> register(String lotId);

  /// Bật (maxAmount != null) / tắt giá tối đa tự trả.
  Future<Auction> setProxy(String id, int? maxAmount);
}
