// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'review_dto.g.dart';

@JsonSerializable()
class ReviewDto {
  const ReviewDto({
    required this.id,
    required this.orderId,
    required this.reviewerName,
    required this.rating,
    required this.createdAt,
    this.comment,
  });

  factory ReviewDto.fromJson(Map<String, Object?> json) =>
      _$ReviewDtoFromJson(json);

  final String id;
  final String orderId;
  final String reviewerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$ReviewDtoToJson(this);
}
