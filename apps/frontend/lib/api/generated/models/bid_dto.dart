// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bid_dto.g.dart';

@JsonSerializable()
class BidDto {
  const BidDto({
    required this.id,
    required this.lotId,
    required this.paddleNumber,
    required this.amount,
    required this.createdAt,
    required this.isAuto,
  });

  factory BidDto.fromJson(Map<String, Object?> json) => _$BidDtoFromJson(json);

  final String id;
  final String lotId;
  final String paddleNumber;
  final int amount;
  final DateTime createdAt;
  final bool isAuto;

  Map<String, Object?> toJson() => _$BidDtoToJson(this);
}
