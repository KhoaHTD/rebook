import 'package:book_marketplace/features/auction/domain/auction.dart';

abstract interface class AuctionRepository {
  Future<List<Auction>> listAuctions();

  /// Phát trạng thái hiện tại của phiên, rồi phát lại mỗi khi có bid mới (realtime).
  Stream<Auction> watchAuction(String id);

  /// Backend kiểm tra hợp lệ (giá tối thiểu, phiên còn mở...) và trả về trạng thái mới.
  Future<Auction> placeBid(String id, int amount);
}
