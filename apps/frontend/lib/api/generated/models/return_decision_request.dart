// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'return_decision_request.g.dart';

@JsonSerializable()
class ReturnDecisionRequest {
  const ReturnDecisionRequest({required this.accept, this.note});

  factory ReturnDecisionRequest.fromJson(Map<String, Object?> json) =>
      _$ReturnDecisionRequestFromJson(json);

  final bool accept;
  final String? note;

  Map<String, Object?> toJson() => _$ReturnDecisionRequestToJson(this);
}
