import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/core/realtime/realtime_client.dart';
import 'package:book_marketplace/features/auction/data/auction_mapper.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/features/auction/domain/auction_repository.dart';

/// Hợp đồng realtime với backend:
/// kênh `auctions/<id>` gửi nguyên một `AuctionDto` (JSON) mỗi khi phiên thay đổi.
class ApiAuctionRepository implements AuctionRepository {
  ApiAuctionRepository(this._client, this._realtime);

  final api.RestClient _client;
  final RealtimeClient _realtime;

  @override
  Future<List<Auction>> listAuctions() => guardApi(() async {
    final dtos = await _client.auctions.listAuctions();
    return dtos.map((d) => d.toDomain()).toList();
  });

  @override
  Stream<Auction> watchAuction(String id) async* {
    yield await guardApi(
      () async => (await _client.auctions.getAuction(id: id)).toDomain(),
    );
    yield* _realtime
        .subscribe('auctions/$id')
        .map((json) => api.AuctionDto.fromJson(json).toDomain());
  }

  @override
  Future<Auction> placeBid(String id, int amount) => guardApi(() async {
    final dto = await _client.auctions.placeBid(
      id: id,
      body: api.PlaceBidRequest(amount: amount),
    );
    return dto.toDomain();
  });
}
