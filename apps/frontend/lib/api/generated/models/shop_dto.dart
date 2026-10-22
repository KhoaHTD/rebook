// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shop_dto.g.dart';

@JsonSerializable()
class ShopDto {
  const ShopDto({
    required this.id,
    required this.userId,
    required this.name,
    required this.pickupAddress,
    required this.ratingAvg,
    required this.ratingCount,
    required this.createdAt,
    this.avatarUrl,
    this.description,
    this.activeListings,
  });

  factory ShopDto.fromJson(Map<String, Object?> json) =>
      _$ShopDtoFromJson(json);

  final String id;
  final String userId;
  final String name;
  final String? avatarUrl;
  final String? description;
  final String pickupAddress;
  final double ratingAvg;
  final int ratingCount;
  final int? activeListings;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$ShopDtoToJson(this);
}
