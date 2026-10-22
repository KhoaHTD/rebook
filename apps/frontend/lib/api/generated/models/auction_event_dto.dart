// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'auction_event_dto_type.dart';
import 'bid_dto.dart';
import 'lot_dto.dart';

part 'auction_event_dto.g.dart';

/// Tin nhắn STOMP trên /topic/sessions/{sessionId}. Lỗi riêng từng người ở /user/queue/errors (ErrorResponse).
@JsonSerializable()
class AuctionEventDto {
  const AuctionEventDto({
    required this.type,
    required this.sessionId,
    required this.serverTime,
    this.lot,
    this.bid,
  });

  factory AuctionEventDto.fromJson(Map<String, Object?> json) =>
      _$AuctionEventDtoFromJson(json);

  final AuctionEventDtoType type;
  final String sessionId;
  final DateTime serverTime;
  final LotDto? lot;
  final BidDto? bid;

  Map<String, Object?> toJson() => _$AuctionEventDtoToJson(this);
}
