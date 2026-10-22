// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_grade.dart';
import 'inspection_result.dart';
import 'seller_decision.dart';

part 'inspection_response.g.dart';

@JsonSerializable()
class InspectionResponse {
  const InspectionResponse({
    this.id,
    this.result,
    this.checklist,
    this.conditionGrade,
    this.conditionReport,
    this.estimateLow,
    this.estimateHigh,
    this.proposedStart,
    this.proposedReserve,
    this.sellerDecision,
    this.sellerCounterReserve,
    this.decidedAt,
    this.createdAt,
  });

  factory InspectionResponse.fromJson(Map<String, Object?> json) =>
      _$InspectionResponseFromJson(json);

  final int? id;
  final InspectionResult? result;
  final Map<String, dynamic>? checklist;
  final ConditionGrade? conditionGrade;
  final String? conditionReport;
  final num? estimateLow;
  final num? estimateHigh;
  final num? proposedStart;
  final num? proposedReserve;
  final SellerDecision? sellerDecision;
  final num? sellerCounterReserve;
  final DateTime? decidedAt;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$InspectionResponseToJson(this);
}
