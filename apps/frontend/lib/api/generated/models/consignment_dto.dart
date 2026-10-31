// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_dto.dart';
import 'consignment_status.dart';
import 'inspection_dto.dart';
import 'lot_status.dart';

part 'consignment_dto.g.dart';

@JsonSerializable()
class ConsignmentDto {
  const ConsignmentDto({
    required this.id,
    required this.sellerName,
    required this.book,
    required this.expectedPrice,
    required this.story,
    required this.status,
    required this.createdAt,
    this.sellerId,
    this.rejectReason,
    this.approvedAt,
    this.appointmentAt,
    this.appointmentCode,
    this.appointmentExpiresAt,
    this.receivedAt,
    this.warehouseCode,
    this.inspection,
    this.lotId,
    this.lotStatus,
    this.hammerPrice,
    this.payout,
  });

  factory ConsignmentDto.fromJson(Map<String, Object?> json) =>
      _$ConsignmentDtoFromJson(json);

  final String id;
  final String? sellerId;
  final String sellerName;
  final BookDto book;
  final int expectedPrice;
  final String story;
  final ConsignmentStatus status;
  final String? rejectReason;
  final DateTime? approvedAt;
  final DateTime? appointmentAt;
  final String? appointmentCode;
  final DateTime? appointmentExpiresAt;
  final DateTime? receivedAt;
  final String? warehouseCode;
  final InspectionDto? inspection;
  final String? lotId;
  final LotStatus? lotStatus;
  final int? hammerPrice;
  final int? payout;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$ConsignmentDtoToJson(this);
}
