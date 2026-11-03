// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ConditionGrade {
  /// The name has been replaced because it contains a keyword. Original name: `NEW`.
  @JsonValue('NEW')
  valueNew('NEW'),
  @JsonValue('LIKE_NEW')
  likeNew('LIKE_NEW'),
  @JsonValue('VERY_GOOD')
  veryGood('VERY_GOOD'),
  @JsonValue('GOOD')
  good('GOOD'),
  @JsonValue('ACCEPTABLE')
  acceptable('ACCEPTABLE'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ConditionGrade(this.json);

  factory ConditionGrade.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<ConditionGrade> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
