// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'register_session_request.g.dart';

@JsonSerializable()
class RegisterSessionRequest {
  const RegisterSessionRequest({
    required this.agreeRules,
    required this.depositAmount,
  });

  factory RegisterSessionRequest.fromJson(Map<String, Object?> json) =>
      _$RegisterSessionRequestFromJson(json);

  final bool agreeRules;

  /// Tối thiểu = depositAmount của phiên; cọc thêm để tăng hạn mức
  final int depositAmount;

  Map<String, Object?> toJson() => _$RegisterSessionRequestToJson(this);
}
