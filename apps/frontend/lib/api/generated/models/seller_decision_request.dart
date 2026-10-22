// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_decision_action.dart';

part 'seller_decision_request.g.dart';

@JsonSerializable()
class SellerDecisionRequest {
  const SellerDecisionRequest({
    required this.decision,
    this.counterReserve,
    this.agreeTerms,
  });

  factory SellerDecisionRequest.fromJson(Map<String, Object?> json) =>
      _$SellerDecisionRequestFromJson(json);

  final SellerDecisionAction decision;
  final num? counterReserve;
  final bool? agreeTerms;

  Map<String, Object?> toJson() => _$SellerDecisionRequestToJson(this);
}
