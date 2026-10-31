// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'lock_user_request.g.dart';

@JsonSerializable()
class LockUserRequest {
  const LockUserRequest({required this.locked, this.reason});

  factory LockUserRequest.fromJson(Map<String, Object?> json) =>
      _$LockUserRequestFromJson(json);

  final bool locked;
  final String? reason;

  Map<String, Object?> toJson() => _$LockUserRequestToJson(this);
}
