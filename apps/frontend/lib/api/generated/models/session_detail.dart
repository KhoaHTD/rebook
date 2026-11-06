// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lot_public.dart';
import 'registration_response.dart';
import 'session_summary.dart';

part 'session_detail.g.dart';

@JsonSerializable()
class SessionDetail {
  const SessionDetail({
    this.session,
    this.lotDurationSec,
    this.softCloseSec,
    this.lots,
    this.myRegistration,
  });

  factory SessionDetail.fromJson(Map<String, Object?> json) =>
      _$SessionDetailFromJson(json);

  final SessionSummary? session;
  final int? lotDurationSec;
  final int? softCloseSec;
  final List<LotPublic>? lots;
  final RegistrationResponse? myRegistration;

  Map<String, Object?> toJson() => _$SessionDetailToJson(this);
}
