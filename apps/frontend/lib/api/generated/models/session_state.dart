// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lot_live.dart';
import 'registration_response.dart';
import 'session_status.dart';

part 'session_state.g.dart';

@JsonSerializable()
class SessionState {
  const SessionState({
    this.serverTime,
    this.sessionId,
    this.status,
    this.currentLot,
    this.nextLotAt,
    this.remainingLots,
    this.pausedRemainingMs,
    this.me,
    this.myProxyMax,
  });

  factory SessionState.fromJson(Map<String, Object?> json) =>
      _$SessionStateFromJson(json);

  final DateTime? serverTime;
  final int? sessionId;
  final SessionStatus? status;
  final LotLive? currentLot;
  final DateTime? nextLotAt;
  final int? remainingLots;
  final int? pausedRemainingMs;
  final RegistrationResponse? me;
  final num? myProxyMax;

  Map<String, Object?> toJson() => _$SessionStateToJson(this);
}
