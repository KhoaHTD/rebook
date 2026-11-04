// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'return_reason.dart';

part 'return_create_request.g.dart';

@JsonSerializable()
class ReturnCreateRequest {
  const ReturnCreateRequest({
    required this.reason,
    required this.description,
    required this.images,
  });

  factory ReturnCreateRequest.fromJson(Map<String, Object?> json) =>
      _$ReturnCreateRequestFromJson(json);

  final ReturnReason reason;
  final String description;
  final List<String> images;

  Map<String, Object?> toJson() => _$ReturnCreateRequestToJson(this);
}
