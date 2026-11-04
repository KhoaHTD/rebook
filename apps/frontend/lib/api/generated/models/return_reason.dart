// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ReturnReason {
  @JsonValue('WRONG_CONDITION')
  wrongCondition('WRONG_CONDITION'),
  @JsonValue('MISSING_PAGES')
  missingPages('MISSING_PAGES'),
  @JsonValue('WRONG_EDITION')
  wrongEdition('WRONG_EDITION'),
  @JsonValue('OTHER_NOT_AS_DESCRIBED')
  otherNotAsDescribed('OTHER_NOT_AS_DESCRIBED'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ReturnReason(this.json);

  factory ReturnReason.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<ReturnReason> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
