// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_grade.dart';
import 'listing_status.dart';
import 'shop_brief.dart';

part 'listing_summary.g.dart';

@JsonSerializable()
class ListingSummary {
  const ListingSummary({
    this.id,
    this.title,
    this.author,
    this.coverUrl,
    this.conditionGrade,
    this.price,
    this.stock,
    this.soldCount,
    this.status,
    this.shop,
    this.createdAt,
  });

  factory ListingSummary.fromJson(Map<String, Object?> json) =>
      _$ListingSummaryFromJson(json);

  final int? id;
  final String? title;
  final String? author;
  final String? coverUrl;
  final ConditionGrade? conditionGrade;
  final num? price;
  final int? stock;
  final int? soldCount;
  final ListingStatus? status;
  final ShopBrief? shop;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$ListingSummaryToJson(this);
}
