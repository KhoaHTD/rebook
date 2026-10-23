// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'decision_request.g.dart';

@JsonSerializable()
class DecisionRequest {
  const DecisionRequest({this.approve, this.note});

  factory DecisionRequest.fromJson(Map<String, Object?> json) =>
      _$DecisionRequestFromJson(json);

  final bool? approve;
  final String? note;

  Map<String, Object?> toJson() => _$DecisionRequestToJson(this);
}
