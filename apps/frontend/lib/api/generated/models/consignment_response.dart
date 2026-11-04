// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_response.dart';
import 'consignment_status.dart';
import 'inspection_response.dart';
import 'lot_brief.dart';
import 'warehouse_response.dart';

part 'consignment_response.g.dart';

@JsonSerializable()
class ConsignmentResponse {
  const ConsignmentResponse({
    this.id,
    this.code,
    this.status,
    this.sellerId,
    this.sellerName,
    this.book,
    this.expectedPrice,
    this.provenance,
    this.reviewNote,
    this.appointmentAt,
    this.appointmentCode,
    this.approvedAt,
    this.receivedAt,
    this.inspection,
    this.lot,
    this.warehouse,
    this.createdAt,
    this.updatedAt,
  });

  factory ConsignmentResponse.fromJson(Map<String, Object?> json) =>
      _$ConsignmentResponseFromJson(json);

  final int? id;
  final String? code;
  final ConsignmentStatus? status;
  final int? sellerId;
  final String? sellerName;
  final BookResponse? book;
  final num? expectedPrice;
  final String? provenance;
  final String? reviewNote;
  final DateTime? appointmentAt;
  final String? appointmentCode;
  final DateTime? approvedAt;
  final DateTime? receivedAt;
  final InspectionResponse? inspection;
  final LotBrief? lot;
  final WarehouseResponse? warehouse;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toJson() => _$ConsignmentResponseToJson(this);
}
