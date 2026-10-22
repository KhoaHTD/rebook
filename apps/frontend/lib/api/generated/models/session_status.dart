// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum SessionStatus {
  @JsonValue('DRAFT')
  draft('DRAFT'),
  @JsonValue('PUBLISHED')
  published('PUBLISHED'),
  @JsonValue('POSTPONED')
  postponed('POSTPONED'),
  @JsonValue('CONFIRMED')
  confirmed('CONFIRMED'),
  @JsonValue('LIVE')
  live('LIVE'),
  @JsonValue('PAUSED')
  paused('PAUSED'),
  @JsonValue('ENDED')
  ended('ENDED'),
  @JsonValue('CANCELLED')
  cancelled('CANCELLED'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const SessionStatus(this.json);

  factory SessionStatus.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<SessionStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
