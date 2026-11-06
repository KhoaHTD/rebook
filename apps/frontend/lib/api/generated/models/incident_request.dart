// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'incident_type.dart';

part 'incident_request.g.dart';

@JsonSerializable()
class IncidentRequest {
  const IncidentRequest({
    required this.type,
    required this.description,
    this.photoUrls,
  });
  
  factory IncidentRequest.fromJson(Map<String, Object?> json) => _$IncidentRequestFromJson(json);
  
  final IncidentType type;
  final String description;
  final List<String>? photoUrls;

  Map<String, Object?> toJson() => _$IncidentRequestToJson(this);
}
