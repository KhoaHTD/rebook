// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'collect_result.g.dart';

@JsonSerializable()
class CollectResult {
  const CollectResult({
    this.collected,
    this.stillOwed,
  });
  
  factory CollectResult.fromJson(Map<String, Object?> json) => _$CollectResultFromJson(json);
  
  final num? collected;
  final num? stillOwed;

  Map<String, Object?> toJson() => _$CollectResultToJson(this);
}
