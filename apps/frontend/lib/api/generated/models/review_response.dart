// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'review_response.g.dart';

@JsonSerializable()
class ReviewResponse {
  const ReviewResponse({
    this.id,
    this.orderId,
    this.reviewerName,
    this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewResponse.fromJson(Map<String, Object?> json) =>
      _$ReviewResponseFromJson(json);

  final int? id;
  final int? orderId;
  final String? reviewerName;
  final int? rating;
  final String? comment;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$ReviewResponseToJson(this);
}
