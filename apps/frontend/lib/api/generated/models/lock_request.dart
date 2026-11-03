// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'lock_request.g.dart';

@JsonSerializable()
class LockRequest {
  const LockRequest({required this.reason});

  factory LockRequest.fromJson(Map<String, Object?> json) =>
      _$LockRequestFromJson(json);

  final String reason;

  Map<String, Object?> toJson() => _$LockRequestToJson(this);
}
