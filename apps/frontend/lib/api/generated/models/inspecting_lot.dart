// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'inspecting_lot.g.dart';

@JsonSerializable()
class InspectingLot {
  const InspectingLot({
    this.lotId,
    this.consignmentId,
    this.consignmentCode,
    this.bookTitle,
    this.hammerPrice,
    this.closedAt,
  });
  
  factory InspectingLot.fromJson(Map<String, Object?> json) => _$InspectingLotFromJson(json);
  
  final int? lotId;
  final int? consignmentId;
  final String? consignmentCode;
  final String? bookTitle;
  final num? hammerPrice;
  final DateTime? closedAt;

  Map<String, Object?> toJson() => _$InspectingLotToJson(this);
}
