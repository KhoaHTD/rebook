// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lot_close_result.dart';

part 'lot_result.g.dart';

@JsonSerializable()
class LotResult {
  const LotResult({
    this.lotNumber,
    this.lotId,
    this.title,
    this.result,
    this.hammerPrice,
    this.winnerPaddle,
  });

  factory LotResult.fromJson(Map<String, Object?> json) =>
      _$LotResultFromJson(json);

  final int? lotNumber;
  final int? lotId;
  final String? title;
  final LotCloseResult? result;
  final num? hammerPrice;
  final String? winnerPaddle;

  Map<String, Object?> toJson() => _$LotResultToJson(this);
}
