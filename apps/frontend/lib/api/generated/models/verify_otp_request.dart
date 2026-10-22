// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'verify_otp_request.g.dart';

@JsonSerializable()
class VerifyOtpRequest {
  const VerifyOtpRequest({required this.email, required this.code});

  factory VerifyOtpRequest.fromJson(Map<String, Object?> json) =>
      _$VerifyOtpRequestFromJson(json);

  final String email;
  final String code;

  Map<String, Object?> toJson() => _$VerifyOtpRequestToJson(this);
}
