// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Vòng đời ký gửi trước khi thành lô: SUBMITTED → PRE_APPROVED (hoặc PRE_REJECTED) → APPOINTMENT_BOOKED (hoặc EXPIRED) → RECEIVED → INSPECTED (hoặc INSPECTION_FAILED → RETURNED) → ACCEPTED (thành lô READY) / WITHDRAWN
@JsonEnum()
enum ConsignmentStatus {
  @JsonValue('SUBMITTED')
  submitted('SUBMITTED'),
  @JsonValue('PRE_APPROVED')
  preApproved('PRE_APPROVED'),
  @JsonValue('PRE_REJECTED')
  preRejected('PRE_REJECTED'),
  @JsonValue('APPOINTMENT_BOOKED')
  appointmentBooked('APPOINTMENT_BOOKED'),
  @JsonValue('EXPIRED')
  expired('EXPIRED'),
  @JsonValue('RECEIVED')
  received('RECEIVED'),
  @JsonValue('INSPECTED')
  inspected('INSPECTED'),
  @JsonValue('INSPECTION_FAILED')
  inspectionFailed('INSPECTION_FAILED'),
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
