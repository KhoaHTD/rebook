// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum IncidentStage {
  @JsonValue('UNINSPECTED')
  uninspected('UNINSPECTED'),
  @JsonValue('INSPECTED')
  inspected('INSPECTED'),
  @JsonValue('SOLD_PAID')
  soldPaid('SOLD_PAID'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const IncidentStage(this.json);

  factory IncidentStage.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<IncidentStage> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
