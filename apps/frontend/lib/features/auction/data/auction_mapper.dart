import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/shared/data/book_mapper.dart';

extension AuctionDtoMapper on api.AuctionDto {
  Auction toDomain() => Auction(
    id: id,
    book: book.toDomain(),
    currentPrice: currentPrice,
    minIncrement: minIncrement,
    endsAt: endsAt.toLocal(),
    bidCount: bidCount,
    highestBidder: highestBidder,
  );
}
