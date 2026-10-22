// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'otp_sent_response.g.dart';

@JsonSerializable()
class OtpSentResponse {
  const OtpSentResponse({required this.email, required this.expiresInSec});

  factory OtpSentResponse.fromJson(Map<String, Object?> json) =>
      _$OtpSentResponseFromJson(json);

  final String email;
  final int expiresInSec;

  Map<String, Object?> toJson() => _$OtpSentResponseToJson(this);
}
