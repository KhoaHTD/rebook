// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'unsold_action.dart';

part 'unsold_decision_request.g.dart';

@JsonSerializable()
class UnsoldDecisionRequest {
  const UnsoldDecisionRequest({
    required this.action,
    this.newReserve,
    this.listingPrice,
  });

  factory UnsoldDecisionRequest.fromJson(Map<String, Object?> json) =>
      _$UnsoldDecisionRequestFromJson(json);

  final UnsoldAction action;
  final num? newReserve;
  final num? listingPrice;

  Map<String, Object?> toJson() => _$UnsoldDecisionRequestToJson(this);
}
