// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lot_close_result.dart';
import 'lot_status.dart';

part 'lot_brief.g.dart';

@JsonSerializable()
class LotBrief {
  const LotBrief({
    this.id,
    this.status,
    this.sessionId,
    this.lotNumber,
    this.startPrice,
    this.reservePrice,
    this.hammerPrice,
    this.closeResult,
    this.rounds,
  });

  factory LotBrief.fromJson(Map<String, Object?> json) =>
      _$LotBriefFromJson(json);

  final int? id;
  final LotStatus? status;
  final int? sessionId;
  final int? lotNumber;
  final num? startPrice;
  final num? reservePrice;
  final num? hammerPrice;
  final LotCloseResult? closeResult;
  final int? rounds;

  Map<String, Object?> toJson() => _$LotBriefToJson(this);
}
