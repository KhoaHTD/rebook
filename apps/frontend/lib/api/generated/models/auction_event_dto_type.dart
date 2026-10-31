// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum AuctionEventDtoType {
  @JsonValue('LOT_OPENED')
  lotOpened('LOT_OPENED'),
  @JsonValue('BID_PLACED')
  bidPlaced('BID_PLACED'),
  @JsonValue('LOT_CLOSED')
  lotClosed('LOT_CLOSED'),
  @JsonValue('SESSION_PAUSED')
  sessionPaused('SESSION_PAUSED'),
  @JsonValue('SESSION_RESUMED')
  sessionResumed('SESSION_RESUMED'),
  @JsonValue('SESSION_ENDED')
  sessionEnded('SESSION_ENDED'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const AuctionEventDtoType(this.json);

  factory AuctionEventDtoType.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<AuctionEventDtoType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
