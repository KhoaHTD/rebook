// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ReturnStatus {
  @JsonValue('PENDING')
  pending('PENDING'),
  @JsonValue('ACCEPTED')
  accepted('ACCEPTED'),
  @JsonValue('REJECTED')
  rejected('REJECTED'),
  @JsonValue('ESCALATED')
  escalated('ESCALATED'),
  @JsonValue('RESOLVED_REFUND')
  resolvedRefund('RESOLVED_REFUND'),
  @JsonValue('RESOLVED_NO_REFUND')
  resolvedNoRefund('RESOLVED_NO_REFUND'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ReturnStatus(this.json);

  factory ReturnStatus.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<ReturnStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
