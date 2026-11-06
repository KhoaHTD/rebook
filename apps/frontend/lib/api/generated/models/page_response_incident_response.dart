// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'incident_response.dart';

part 'page_response_incident_response.g.dart';

@JsonSerializable()
class PageResponseIncidentResponse {
  const PageResponseIncidentResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });
  
  factory PageResponseIncidentResponse.fromJson(Map<String, Object?> json) => _$PageResponseIncidentResponseFromJson(json);
  
  final List<IncidentResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseIncidentResponseToJson(this);
}
