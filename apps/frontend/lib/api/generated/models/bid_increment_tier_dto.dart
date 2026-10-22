// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bid_increment_tier_dto.g.dart';

@JsonSerializable()
class BidIncrementTierDto {
  const BidIncrementTierDto({required this.fromPrice, required this.increment});

  factory BidIncrementTierDto.fromJson(Map<String, Object?> json) =>
      _$BidIncrementTierDtoFromJson(json);

  final int fromPrice;
  final int increment;

  Map<String, Object?> toJson() => _$BidIncrementTierDtoToJson(this);
}
