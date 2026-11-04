// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'review_response.dart';

part 'page_response_review_response.g.dart';

@JsonSerializable()
class PageResponseReviewResponse {
  const PageResponseReviewResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseReviewResponse.fromJson(Map<String, Object?> json) =>
      _$PageResponseReviewResponseFromJson(json);

  final List<ReviewResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseReviewResponseToJson(this);
}
