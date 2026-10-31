// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'admin_action.dart';

part 'activity_log_dto.g.dart';

@JsonSerializable()
class ActivityLogDto {
  const ActivityLogDto({
    required this.id,
    required this.adminName,
    required this.action,
    required this.createdAt,
    this.target,
    this.note,
  });

  factory ActivityLogDto.fromJson(Map<String, Object?> json) =>
      _$ActivityLogDtoFromJson(json);

  final String id;
  final String adminName;
  final AdminAction action;

  /// Đối tượng bị tác động (tên sách, email người dùng, mã yêu cầu rút…).
  final String? target;
  final String? note;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$ActivityLogDtoToJson(this);
}
