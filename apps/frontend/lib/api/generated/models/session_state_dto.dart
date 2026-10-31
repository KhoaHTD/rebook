// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'auction_session_dto.dart';
import 'bid_dto.dart';
import 'lot_dto.dart';
import 'registration_dto.dart';

part 'session_state_dto.g.dart';

@JsonSerializable()
class SessionStateDto {
  const SessionStateDto({
    required this.session,
    required this.lots,
    required this.serverTime,
    required this.recentBids,
    this.currentLot,
    this.myRegistration,
    this.viewerCount,
  });

  factory SessionStateDto.fromJson(Map<String, Object?> json) =>
      _$SessionStateDtoFromJson(json);

  final AuctionSessionDto session;
  final LotDto? currentLot;
  final List<LotDto> lots;
  final DateTime serverTime;
  final RegistrationDto? myRegistration;
  final List<BidDto> recentBids;
  final int? viewerCount;

  Map<String, Object?> toJson() => _$SessionStateDtoToJson(this);
}
