// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'reinspect_request.g.dart';

@JsonSerializable()
class ReinspectRequest {
  const ReinspectRequest({
    required this.report,
    this.passed,
  });
  
  factory ReinspectRequest.fromJson(Map<String, Object?> json) => _$ReinspectRequestFromJson(json);
  
  final bool? passed;
  final String report;

  Map<String, Object?> toJson() => _$ReinspectRequestToJson(this);
}
