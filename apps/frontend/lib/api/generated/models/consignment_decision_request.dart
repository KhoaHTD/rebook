// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'seller_decision.dart';

part 'consignment_decision_request.g.dart';

@JsonSerializable()
class ConsignmentDecisionRequest {
  const ConsignmentDecisionRequest({
    required this.decision,
    required this.agreeTerms,
    this.counterReserve,
  });

  factory ConsignmentDecisionRequest.fromJson(Map<String, Object?> json) =>
      _$ConsignmentDecisionRequestFromJson(json);

  final SellerDecision decision;
  final int? counterReserve;

  /// Đồng ý hợp đồng ký gửi điện tử (hoa hồng
  final bool agreeTerms;

  Map<String, Object?> toJson() => _$ConsignmentDecisionRequestToJson(this);
}
