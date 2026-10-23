// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'auction_session_dto.dart';
import 'listing_dto.dart';
import 'shop_summary_dto.dart';

part 'home_feed_dto.g.dart';

@JsonSerializable()
class HomeFeedDto {
  const HomeFeedDto({
    required this.featuredShops,
    required this.trending,
    required this.newArrivals,
    required this.liveSessions,
  });

  factory HomeFeedDto.fromJson(Map<String, Object?> json) =>
      _$HomeFeedDtoFromJson(json);

  final List<ShopSummaryDto> featuredShops;
  final List<ListingDto> trending;
  final List<ListingDto> newArrivals;
  final List<AuctionSessionDto> liveSessions;

  Map<String, Object?> toJson() => _$HomeFeedDtoToJson(this);
}
