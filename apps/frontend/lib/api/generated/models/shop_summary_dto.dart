// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shop_summary_dto.g.dart';

@JsonSerializable()
class ShopSummaryDto {
  const ShopSummaryDto({
    required this.id,
    required this.name,
    required this.ratingAvg,
    required this.ratingCount,
    this.avatarUrl,
  });

  factory ShopSummaryDto.fromJson(Map<String, Object?> json) =>
      _$ShopSummaryDtoFromJson(json);

  final String id;
  final String name;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;

  Map<String, Object?> toJson() => _$ShopSummaryDtoToJson(this);
}
