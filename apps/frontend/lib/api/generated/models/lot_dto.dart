// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_dto.dart';
import 'lot_outcome.dart';
import 'lot_status.dart';
import 'signature_status.dart';

part 'lot_dto.g.dart';

@JsonSerializable()
class LotDto {
  const LotDto({
    required this.id,
    required this.sessionId,
    required this.lotNumber,
    required this.book,
    required this.estimateLow,
    required this.estimateHigh,
    required this.startPrice,
    required this.currentPrice,
    required this.bidCount,
    required this.status,
    required this.watched,
    this.story,
    this.conditionReport,
    this.signature,
    this.outcome,
    this.endsAt,
    this.hammerPrice,
    this.leadingPaddle,
  });

  factory LotDto.fromJson(Map<String, Object?> json) => _$LotDtoFromJson(json);

  final String id;
  final String sessionId;
  final int lotNumber;
  final BookDto book;
  final String? story;
  final String? conditionReport;
  final SignatureStatus? signature;
  final int estimateLow;
  final int estimateHigh;
  final int startPrice;
  final int currentPrice;
  final int bidCount;
  final LotStatus status;
  final LotOutcome? outcome;
  final DateTime? endsAt;
  final int? hammerPrice;
  final String? leadingPaddle;
  final bool watched;

  Map<String, Object?> toJson() => _$LotDtoToJson(this);
}
