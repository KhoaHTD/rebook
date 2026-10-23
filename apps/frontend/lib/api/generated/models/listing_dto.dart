// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_dto.dart';
import 'listing_status.dart';
import 'shop_summary_dto.dart';

part 'listing_dto.g.dart';

@JsonSerializable()
class ListingDto {
  const ListingDto({
    required this.id,
    required this.book,
    required this.shop,
    required this.price,
    required this.stock,
    required this.status,
    required this.createdAt,
    this.rejectReason,
  });

  factory ListingDto.fromJson(Map<String, Object?> json) =>
      _$ListingDtoFromJson(json);

  final String id;
  final BookDto book;
  final ShopSummaryDto shop;
  final int price;
  final int stock;
  final ListingStatus status;
  final String? rejectReason;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$ListingDtoToJson(this);
}
