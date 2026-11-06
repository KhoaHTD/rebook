// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'incident_stage.dart';
import 'incident_status.dart';
import 'incident_type.dart';

part 'incident_response.g.dart';

@JsonSerializable()
class IncidentResponse {
  const IncidentResponse({
    this.id,
    this.warehouseItemId,
    this.consignmentId,
    this.consignmentCode,
    this.bookTitle,
    this.type,
    this.description,
    this.images,
    this.reportedBy,
    this.status,
    this.stage,
    this.baseAmount,
    this.sellerPercent,
    this.sellerAmount,
    this.buyerId,
    this.buyerAmount,
    this.orderId,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
    this.createdAt,
  });

  factory IncidentResponse.fromJson(Map<String, Object?> json) =>
      _$IncidentResponseFromJson(json);

  final int? id;
  final int? warehouseItemId;
  final int? consignmentId;
  final String? consignmentCode;
  final String? bookTitle;
  final IncidentType? type;
  final String? description;
  final List<String>? images;
  final int? reportedBy;
  final IncidentStatus? status;
  final IncidentStage? stage;
  final num? baseAmount;
  final int? sellerPercent;
  final num? sellerAmount;
  final int? buyerId;
  final num? buyerAmount;
  final int? orderId;
  final int? decidedBy;
  final DateTime? decidedAt;
  final String? decisionNote;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$IncidentResponseToJson(this);
}
