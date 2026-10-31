// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// READY → SCHEDULED → LIVE → SOLD → COMPLETED; LIVE → UNSOLD → READY/RETURNED; SCHEDULED → READY khi phiên hủy; SOLD → READY khi người thắng bỏ thanh toán
@JsonEnum()
enum LotStatus {
  @JsonValue('READY')
  ready('READY'),
  @JsonValue('SCHEDULED')
  scheduled('SCHEDULED'),
  @JsonValue('LIVE')
  live('LIVE'),
  @JsonValue('SOLD')
  sold('SOLD'),
  @JsonValue('UNSOLD')
  unsold('UNSOLD'),
  @JsonValue('COMPLETED')
  completed('COMPLETED'),
  @JsonValue('RETURNED')
  returned('RETURNED'),
  @JsonValue('CANCELLED')
  cancelled('CANCELLED'),

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
