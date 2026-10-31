// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lot_outcome.dart';

part 'lot_result_dto.g.dart';

@JsonSerializable()
class LotResultDto {
  const LotResultDto({
    required this.lotId,
    required this.lotNumber,
    required this.title,
    required this.outcome,
    this.hammerPrice,
    this.winnerPaddle,
    this.wonByMe,
  });

  factory LotResultDto.fromJson(Map<String, Object?> json) =>
      _$LotResultDtoFromJson(json);

  final String lotId;
  final int lotNumber;
  final String title;
  final LotOutcome outcome;
  final int? hammerPrice;
  final String? winnerPaddle;
  final bool? wonByMe;

  Map<String, Object?> toJson() => _$LotResultDtoToJson(this);
}
