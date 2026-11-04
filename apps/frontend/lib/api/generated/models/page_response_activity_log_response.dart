// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'activity_log_response.dart';

part 'page_response_activity_log_response.g.dart';

@JsonSerializable()
class PageResponseActivityLogResponse {
  const PageResponseActivityLogResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseActivityLogResponse.fromJson(Map<String, Object?> json) =>
      _$PageResponseActivityLogResponseFromJson(json);

  final List<ActivityLogResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() =>
      _$PageResponseActivityLogResponseToJson(this);
}
