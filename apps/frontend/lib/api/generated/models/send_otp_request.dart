// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'otp_purpose.dart';

part 'send_otp_request.g.dart';

@JsonSerializable()
class SendOtpRequest {
  const SendOtpRequest({required this.purpose});

  factory SendOtpRequest.fromJson(Map<String, Object?> json) =>
      _$SendOtpRequestFromJson(json);

  final OtpPurpose purpose;

  Map<String, Object?> toJson() => _$SendOtpRequestToJson(this);
}
