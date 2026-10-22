// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ConsignmentStatus {
  @JsonValue('SUBMITTED')
  submitted('SUBMITTED'),
  @JsonValue('APPROVED')
  approved('APPROVED'),
  @JsonValue('REJECTED')
  rejected('REJECTED'),
  @JsonValue('APPOINTMENT_BOOKED')
  appointmentBooked('APPOINTMENT_BOOKED'),
  @JsonValue('EXPIRED')
  expired('EXPIRED'),
  @JsonValue('RECEIVED')
  received('RECEIVED'),
  @JsonValue('INSPECTION_FAILED')
  inspectionFailed('INSPECTION_FAILED'),
  @JsonValue('AWAITING_SELLER')
  awaitingSeller('AWAITING_SELLER'),
  @JsonValue('ACCEPTED')
  accepted('ACCEPTED'),
  @JsonValue('WITHDRAWN')
  withdrawn('WITHDRAWN'),
  @JsonValue('RETURNED')
  returned('RETURNED'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ConsignmentStatus(this.json);

  factory ConsignmentStatus.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<ConsignmentStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
