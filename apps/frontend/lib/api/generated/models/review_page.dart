// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'review_dto.dart';

part 'review_page.g.dart';

@JsonSerializable()
class ReviewPage {
  const ReviewPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  factory ReviewPage.fromJson(Map<String, Object?> json) =>
      _$ReviewPageFromJson(json);

  final List<ReviewDto> items;
  final int page;
  final int size;
  final int total;

  Map<String, Object?> toJson() => _$ReviewPageToJson(this);
}
