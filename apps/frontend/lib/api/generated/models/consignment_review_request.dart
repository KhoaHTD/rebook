// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'consignment_review_request.g.dart';

@JsonSerializable()
class ConsignmentReviewRequest {
  const ConsignmentReviewRequest({this.approve, this.note});

  factory ConsignmentReviewRequest.fromJson(Map<String, Object?> json) =>
      _$ConsignmentReviewRequestFromJson(json);

  final bool? approve;
  final String? note;

  Map<String, Object?> toJson() => _$ConsignmentReviewRequestToJson(this);
}
