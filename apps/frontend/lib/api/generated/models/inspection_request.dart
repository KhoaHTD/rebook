// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_grade.dart';
import 'inspection_checklist_dto.dart';
import 'inspection_result.dart';

part 'inspection_request.g.dart';

@JsonSerializable()
class InspectionRequest {
  const InspectionRequest({
    required this.result,
    required this.checklist,
    required this.conditionGrade,
    required this.conditionReport,
    required this.staffImageUrls,
    this.estimateLow,
    this.estimateHigh,
    this.proposedStart,
    this.proposedReserve,
  });

  factory InspectionRequest.fromJson(Map<String, Object?> json) =>
      _$InspectionRequestFromJson(json);

  final InspectionResult result;
  final InspectionChecklistDto checklist;
  final ConditionGrade conditionGrade;
  final String conditionReport;
  final List<String> staffImageUrls;
  final int? estimateLow;
  final int? estimateHigh;
  final int? proposedStart;
  final int? proposedReserve;

  Map<String, Object?> toJson() => _$InspectionRequestToJson(this);
}
