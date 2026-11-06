// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'incident_reject_request.g.dart';

@JsonSerializable()
class IncidentRejectRequest {
  const IncidentRejectRequest({
    required this.reason,
  });
  
  factory IncidentRejectRequest.fromJson(Map<String, Object?> json) => _$IncidentRejectRequestFromJson(json);
  
  final String reason;

  Map<String, Object?> toJson() => _$IncidentRejectRequestToJson(this);
}
