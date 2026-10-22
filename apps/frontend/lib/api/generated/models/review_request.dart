// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'review_request.g.dart';

@JsonSerializable()
class ReviewRequest {
  const ReviewRequest({this.approve, this.note});

  factory ReviewRequest.fromJson(Map<String, Object?> json) =>
      _$ReviewRequestFromJson(json);

  final bool? approve;
  final String? note;

  Map<String, Object?> toJson() => _$ReviewRequestToJson(this);
}
