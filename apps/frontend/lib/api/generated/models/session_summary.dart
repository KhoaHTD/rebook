// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'session_status.dart';

part 'session_summary.g.dart';

@JsonSerializable()
class SessionSummary {
  const SessionSummary({
    this.id,
    this.title,
    this.description,
    this.coverUrl,
    this.startAt,
    this.registrationDeadline,
    this.minParticipants,
    this.depositAmount,
    this.status,
    this.lotCount,
    this.registeredCount,
    this.endedAt,
  });

  factory SessionSummary.fromJson(Map<String, Object?> json) =>
      _$SessionSummaryFromJson(json);

  final int? id;
  final String? title;
  final String? description;
  final String? coverUrl;
  final DateTime? startAt;
  final DateTime? registrationDeadline;
  final int? minParticipants;
  final num? depositAmount;
  final SessionStatus? status;
  final int? lotCount;
  final int? registeredCount;
  final DateTime? endedAt;

  Map<String, Object?> toJson() => _$SessionSummaryToJson(this);
}
