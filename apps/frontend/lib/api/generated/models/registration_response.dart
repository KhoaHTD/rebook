// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'registration_status.dart';

part 'registration_response.g.dart';

@JsonSerializable()
class RegistrationResponse {
  const RegistrationResponse({
    this.id,
    this.sessionId,
    this.paddle,
    this.depositAmount,
    this.bidLimit,
    this.committed,
    this.remainingLimit,
    this.status,
    this.createdAt,
  });

  factory RegistrationResponse.fromJson(Map<String, Object?> json) =>
      _$RegistrationResponseFromJson(json);

  final int? id;
  final int? sessionId;
  final String? paddle;
  final num? depositAmount;
  final num? bidLimit;
  final num? committed;
  final num? remainingLimit;
  final RegistrationStatus? status;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$RegistrationResponseToJson(this);
}
