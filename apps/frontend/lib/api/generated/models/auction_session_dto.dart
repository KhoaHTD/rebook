// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'session_status.dart';

part 'auction_session_dto.g.dart';

@JsonSerializable()
class AuctionSessionDto {
  const AuctionSessionDto({
    required this.id,
    required this.title,
    required this.startAt,
    required this.registrationDeadline,
    required this.minParticipants,
    required this.depositAmount,
    required this.lotDurationSec,
    required this.softCloseSec,
    required this.status,
    required this.lotCount,
    required this.registeredCount,
    this.description,
    this.coverImageUrl,
    this.currentLotId,
    this.watcherCount,
  });

  factory AuctionSessionDto.fromJson(Map<String, Object?> json) =>
      _$AuctionSessionDtoFromJson(json);

  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final DateTime startAt;
  final DateTime registrationDeadline;
  final int minParticipants;
  final int depositAmount;
  final int lotDurationSec;
  final int softCloseSec;
  final SessionStatus status;
  final int lotCount;
  final int registeredCount;
  final String? currentLotId;
  final int? watcherCount;

  Map<String, Object?> toJson() => _$AuctionSessionDtoToJson(this);
}
