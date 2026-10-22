// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum RegistrationStatus {
  @JsonValue('PENDING_DEPOSIT')
  pendingDeposit('PENDING_DEPOSIT'),
  @JsonValue('APPROVED')
  approved('APPROVED'),
  @JsonValue('REFUNDED')
  refunded('REFUNDED'),
  @JsonValue('APPLIED')
  applied('APPLIED'),
  @JsonValue('FORFEITED')
  forfeited('FORFEITED'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const RegistrationStatus(this.json);

  factory RegistrationStatus.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<RegistrationStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
