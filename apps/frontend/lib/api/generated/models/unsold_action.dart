// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum UnsoldAction {
  @JsonValue('RELIST')
  relist('RELIST'),
  @JsonValue('CONVERT_TO_LISTING')
  convertToListing('CONVERT_TO_LISTING'),

  /// The name has been replaced because it contains a keyword. Original name: `RETURN`.
  @JsonValue('RETURN')
  valueReturn('RETURN'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const UnsoldAction(this.json);

  factory UnsoldAction.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<UnsoldAction> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
