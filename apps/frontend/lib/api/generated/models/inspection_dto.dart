// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_grade.dart';
import 'inspection_checklist_dto.dart';
import 'inspection_result.dart';
import 'seller_decision.dart';

part 'inspection_dto.g.dart';

@JsonSerializable()
class InspectionDto {
  const InspectionDto({
    required this.id,
    required this.result,
    required this.checklist,
    required this.conditionGrade,
    required this.conditionReport,
    required this.staffImageUrls,
    required this.sellerDecision,
    required this.createdAt,
    this.estimateLow,
    this.estimateHigh,
    this.proposedStart,
    this.proposedReserve,
    this.counterReserve,
  });

  factory InspectionDto.fromJson(Map<String, Object?> json) =>
      _$InspectionDtoFromJson(json);

  final String id;
  final InspectionResult result;
  final InspectionChecklistDto checklist;
  final ConditionGrade conditionGrade;
  final String conditionReport;
  final List<String> staffImageUrls;
  final int? estimateLow;
  final int? estimateHigh;
  final int? proposedStart;

  /// Chỉ trả về cho người bán sở hữu và Staff/Admin
  final int? proposedReserve;
  final SellerDecision sellerDecision;
  final int? counterReserve;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$InspectionDtoToJson(this);
}
