// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'session_request.g.dart';

@JsonSerializable()
class SessionRequest {
  const SessionRequest({
    required this.title,
    required this.startAt,
    required this.registrationDeadline,
    required this.minParticipants,
    required this.depositAmount,
    this.lotDurationSec = 60,
    this.softCloseSec = 15,
    this.description,
  });

  factory SessionRequest.fromJson(Map<String, Object?> json) =>
      _$SessionRequestFromJson(json);

  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime registrationDeadline;
  final int minParticipants;
  final int depositAmount;
  final int lotDurationSec;
  final int softCloseSec;

  Map<String, Object?> toJson() => _$SessionRequestToJson(this);
}
