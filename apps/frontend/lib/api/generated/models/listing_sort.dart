// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ListingSort {
  @JsonValue('NEWEST')
  newest('NEWEST'),
  @JsonValue('PRICE_ASC')
  priceAsc('PRICE_ASC'),
  @JsonValue('PRICE_DESC')
  priceDesc('PRICE_DESC'),
  @JsonValue('RELEVANCE')
  relevance('RELEVANCE'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const ListingSort(this.json);

  factory ListingSort.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<ListingSort> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
