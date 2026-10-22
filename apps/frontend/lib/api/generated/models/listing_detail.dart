// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_response.dart';
import 'listing_status.dart';
import 'shop_brief.dart';

part 'listing_detail.g.dart';

@JsonSerializable()
class ListingDetail {
  const ListingDetail({
    this.id,
    this.price,
    this.stock,
    this.soldCount,
    this.status,
    this.rejectReason,
    this.book,
    this.shop,
    this.createdAt,
    this.updatedAt,
  });

  factory ListingDetail.fromJson(Map<String, Object?> json) =>
      _$ListingDetailFromJson(json);

  final int? id;
  final num? price;
  final int? stock;
  final int? soldCount;
  final ListingStatus? status;
  final String? rejectReason;
  final BookResponse? book;
  final ShopBrief? shop;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => _$ListingDetailToJson(this);
}
