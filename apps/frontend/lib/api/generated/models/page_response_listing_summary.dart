// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'listing_summary.dart';

part 'page_response_listing_summary.g.dart';

@JsonSerializable()
class PageResponseListingSummary {
  const PageResponseListingSummary({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseListingSummary.fromJson(Map<String, Object?> json) =>
      _$PageResponseListingSummaryFromJson(json);

  final List<ListingSummary>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseListingSummaryToJson(this);
}
