// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'auction_session_dto.dart';
import 'lot_result_dto.dart';

part 'session_result_dto.g.dart';

@JsonSerializable()
class SessionResultDto {
  const SessionResultDto({required this.session, required this.results});

  factory SessionResultDto.fromJson(Map<String, Object?> json) =>
      _$SessionResultDtoFromJson(json);

  final AuctionSessionDto session;
  final List<LotResultDto> results;

  Map<String, Object?> toJson() => _$SessionResultDtoToJson(this);
}
