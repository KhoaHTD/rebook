// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lot_live.dart';
import 'session_status.dart';

part 'auction_event.g.dart';

@JsonSerializable()
class AuctionEvent {
  const AuctionEvent({
    this.type,
    this.sessionId,
    this.serverTime,
    this.sessionStatus,
    this.lot,
    this.nextLotAt,
    this.message,
  });

  factory AuctionEvent.fromJson(Map<String, Object?> json) =>
      _$AuctionEventFromJson(json);

  final String? type;
  final int? sessionId;
  final DateTime? serverTime;
  final SessionStatus? sessionStatus;
  final LotLive? lot;
  final DateTime? nextLotAt;
  final String? message;

  Map<String, Object?> toJson() => _$AuctionEventToJson(this);
}
