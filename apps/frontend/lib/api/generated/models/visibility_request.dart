// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'visibility_request.g.dart';

@JsonSerializable()
class VisibilityRequest {
  const VisibilityRequest({required this.visible});

  factory VisibilityRequest.fromJson(Map<String, Object?> json) =>
      _$VisibilityRequestFromJson(json);

  final bool visible;

  Map<String, Object?> toJson() => _$VisibilityRequestToJson(this);
}
