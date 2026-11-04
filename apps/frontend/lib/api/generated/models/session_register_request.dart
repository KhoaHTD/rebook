// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'session_register_request.g.dart';

@JsonSerializable()
class SessionRegisterRequest {
  const SessionRegisterRequest({this.agreeRules});

  factory SessionRegisterRequest.fromJson(Map<String, Object?> json) =>
      _$SessionRegisterRequestFromJson(json);

  final bool? agreeRules;

  Map<String, Object?> toJson() => _$SessionRegisterRequestToJson(this);
}
