// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_dto.dart';

part 'auction_dto.g.dart';

@JsonSerializable()
class AuctionDto {
  const AuctionDto({
    required this.id,
    required this.book,
    required this.currentPrice,
    required this.minIncrement,
    required this.endsAt,
    required this.bidCount,
    this.highestBidder,
  });

  factory AuctionDto.fromJson(Map<String, Object?> json) =>
      _$AuctionDtoFromJson(json);

  final String id;
  final BookDto book;
  final int currentPrice;
  final int minIncrement;
  final DateTime endsAt;
  final int bidCount;
  final String? highestBidder;

  Map<String, Object?> toJson() => _$AuctionDtoToJson(this);
}
