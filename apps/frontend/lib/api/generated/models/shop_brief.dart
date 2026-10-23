// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shop_brief.g.dart';

@JsonSerializable()
class ShopBrief {
  const ShopBrief({
    this.id,
    this.name,
    this.pickupProvince,
    this.ratingAvg,
    this.ratingCount,
  });

  factory ShopBrief.fromJson(Map<String, Object?> json) =>
      _$ShopBriefFromJson(json);

  final int? id;
  final String? name;
  final String? pickupProvince;
  final num? ratingAvg;
  final int? ratingCount;

  Map<String, Object?> toJson() => _$ShopBriefToJson(this);
}
