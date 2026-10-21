import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/shared/domain/book.dart';

part 'auction.freezed.dart';

@freezed
abstract class Auction with _$Auction {
  const Auction._();

  const factory Auction({
    required String id,
    required Book book,
    required int currentPrice,
    required int minIncrement,
    required DateTime endsAt,
    required int bidCount,
    String? highestBidder,
  }) = _Auction;

  /// Giá thấp nhất được phép trả tiếp theo.
  int get nextMinBid => currentPrice + minIncrement;

  bool isEndedAt(DateTime now) => !now.isBefore(endsAt);
}
