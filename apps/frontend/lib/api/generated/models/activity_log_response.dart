// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'activity_log_response.g.dart';

@JsonSerializable()
class ActivityLogResponse {
  const ActivityLogResponse({
    this.id,
    this.adminId,
    this.adminName,
    this.action,
    this.targetType,
    this.targetId,
    this.summary,
    this.createdAt,
  });

  factory ActivityLogResponse.fromJson(Map<String, Object?> json) =>
      _$ActivityLogResponseFromJson(json);

  final int? id;
  final int? adminId;
  final String? adminName;
  final String? action;
  final String? targetType;
  final String? targetId;
  final String? summary;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$ActivityLogResponseToJson(this);
}
