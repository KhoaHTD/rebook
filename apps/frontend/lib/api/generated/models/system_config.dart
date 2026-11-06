// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'system_config.g.dart';

@JsonSerializable()
class SystemConfig {
  const SystemConfig({this.key, this.value, this.description, this.updatedAt});

  factory SystemConfig.fromJson(Map<String, Object?> json) =>
      _$SystemConfigFromJson(json);

  final String? key;
  final String? value;
  final String? description;
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => _$SystemConfigToJson(this);
}
