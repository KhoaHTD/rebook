// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'incident_decision_request.g.dart';

@JsonSerializable()
class IncidentDecisionRequest {
  const IncidentDecisionRequest({this.sellerPercent, this.note});

  factory IncidentDecisionRequest.fromJson(Map<String, Object?> json) =>
      _$IncidentDecisionRequestFromJson(json);

  final int? sellerPercent;
  final String? note;

  Map<String, Object?> toJson() => _$IncidentDecisionRequestToJson(this);
}
