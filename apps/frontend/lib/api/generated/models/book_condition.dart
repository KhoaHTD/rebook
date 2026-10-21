// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum BookCondition {
  @JsonValue('like_new')
  likeNew('like_new'),
  @JsonValue('good')
  good('good'),
  @JsonValue('fair')
  fair('fair'),
  @JsonValue('worn')
  worn('worn'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const BookCondition(this.json);

  factory BookCondition.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<BookCondition> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
