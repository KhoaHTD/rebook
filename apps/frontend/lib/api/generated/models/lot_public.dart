// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_grade.dart';
import 'lot_close_result.dart';
import 'lot_status.dart';

part 'lot_public.g.dart';

@JsonSerializable()
class LotPublic {
  const LotPublic({
    this.id,
    this.sessionId,
    this.lotNumber,
    this.status,
    this.closeResult,
    this.title,
    this.author,
    this.coverUrl,
    this.conditionGrade,
    this.estimateLow,
    this.estimateHigh,
    this.startPrice,
    this.currentPrice,
    this.bidCount,
    this.endsAt,
    this.hammerPrice,
    this.winnerPaddle,
    this.watching,
  });

  factory LotPublic.fromJson(Map<String, Object?> json) =>
      _$LotPublicFromJson(json);

  final int? id;
  final int? sessionId;
  final int? lotNumber;
  final LotStatus? status;
  final LotCloseResult? closeResult;
  final String? title;
  final String? author;
  final String? coverUrl;
  final ConditionGrade? conditionGrade;
  final num? estimateLow;
  final num? estimateHigh;
  final num? startPrice;
  final num? currentPrice;
  final int? bidCount;
  final DateTime? endsAt;
  final num? hammerPrice;
  final String? winnerPaddle;
  final bool? watching;

  Map<String, Object?> toJson() => _$LotPublicToJson(this);
}
