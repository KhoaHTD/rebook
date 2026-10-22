// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum NotificationType {
  @JsonValue('ORDER')
  order('ORDER'),
  @JsonValue('AUCTION_REMINDER')
  auctionReminder('AUCTION_REMINDER'),
  @JsonValue('OUTBID')
  outbid('OUTBID'),
  @JsonValue('AUCTION_WON')
  auctionWon('AUCTION_WON'),
  @JsonValue('AUCTION_RESULT')
  auctionResult('AUCTION_RESULT'),
  @JsonValue('CONSIGNMENT')
  consignment('CONSIGNMENT'),
  @JsonValue('WALLET')
  wallet('WALLET'),
  @JsonValue('SYSTEM')
  system('SYSTEM'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const NotificationType(this.json);

  factory NotificationType.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<NotificationType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
