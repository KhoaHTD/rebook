// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'second_chance_offer_status.dart';

part 'second_chance_offer_dto.g.dart';

@JsonSerializable()
class SecondChanceOfferDto {
  const SecondChanceOfferDto({
    required this.id,
    required this.lotId,
    required this.lotNumber,
    required this.bookTitle,
    required this.amount,
    required this.expiresAt,
    required this.status,
    this.coverUrl,
  });

  factory SecondChanceOfferDto.fromJson(Map<String, Object?> json) =>
      _$SecondChanceOfferDtoFromJson(json);

  final String id;
  final String lotId;
  final int lotNumber;
  final String bookTitle;
  final String? coverUrl;

  /// Giá người nhận lời mời đã trả (giá mua).
  final int amount;

  /// Hạn 24h.
  final DateTime expiresAt;
  final SecondChanceOfferStatus status;

  Map<String, Object?> toJson() => _$SecondChanceOfferDtoToJson(this);
}
