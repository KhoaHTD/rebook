// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'warehouse_status.dart';

part 'warehouse_response.g.dart';

@JsonSerializable()
class WarehouseResponse {
  const WarehouseResponse({
    this.id,
    this.code,
    this.consignmentId,
    this.bookTitle,
    this.shelfCode,
    this.status,
    this.checkedInAt,
    this.checkedOutAt,
    this.checkoutReason,
    this.returnNotifiedAt,
    this.storageFee,
  });

  factory WarehouseResponse.fromJson(Map<String, Object?> json) =>
      _$WarehouseResponseFromJson(json);

  final int? id;
  final String? code;
  final int? consignmentId;
  final String? bookTitle;
  final String? shelfCode;
  final WarehouseStatus? status;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final String? checkoutReason;
  final DateTime? returnNotifiedAt;
  final num? storageFee;

  Map<String, Object?> toJson() => _$WarehouseResponseToJson(this);
}
