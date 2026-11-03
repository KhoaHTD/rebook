// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_grade.dart';
import 'inspection_result.dart';

part 'inspection_request.g.dart';

@JsonSerializable()
class InspectionRequest {
  const InspectionRequest({
    required this.result,
    required this.conditionReport,
    this.checklist,
    this.conditionGrade,
    this.photoUrls,
    this.estimateLow,
    this.estimateHigh,
    this.proposedStart,
    this.proposedReserve,
  });

  factory InspectionRequest.fromJson(Map<String, Object?> json) =>
      _$InspectionRequestFromJson(json);

  final InspectionResult result;
  final Map<String, dynamic>? checklist;
  final ConditionGrade? conditionGrade;
  final String conditionReport;
  final List<String>? photoUrls;
  final num? estimateLow;
  final num? estimateHigh;
  final num? proposedStart;
  final num? proposedReserve;

  Map<String, Object?> toJson() => _$InspectionRequestToJson(this);
}
