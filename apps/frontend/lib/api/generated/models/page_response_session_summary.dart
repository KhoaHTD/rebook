// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'session_summary.dart';

part 'page_response_session_summary.g.dart';

@JsonSerializable()
class PageResponseSessionSummary {
  const PageResponseSessionSummary({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseSessionSummary.fromJson(Map<String, Object?> json) =>
      _$PageResponseSessionSummaryFromJson(json);

  final List<SessionSummary>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseSessionSummaryToJson(this);
}
