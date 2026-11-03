// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum LotStatus {
  @JsonValue('READY')
  ready('READY'),
  @JsonValue('SCHEDULED')
  scheduled('SCHEDULED'),
  @JsonValue('OPEN')
  open('OPEN'),
  @JsonValue('SOLD')
  sold('SOLD'),
  @JsonValue('UNSOLD')
  unsold('UNSOLD'),
  @JsonValue('PAID')
  paid('PAID'),
  @JsonValue('COMPLETED')
  completed('COMPLETED'),
  @JsonValue('CANCELLED')
  cancelled('CANCELLED'),
  @JsonValue('RETURNED')
  returned('RETURNED'),
  @JsonValue('CONVERTED')
  converted('CONVERTED'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const LotStatus(this.json);

  factory LotStatus.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<LotStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
