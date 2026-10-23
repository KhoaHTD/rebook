// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lot_status.dart';
import 'warehouse_status.dart';

part 'warehouse_item_dto.g.dart';

@JsonSerializable()
class WarehouseItemDto {
  const WarehouseItemDto({
    required this.id,
    required this.consignmentId,
    required this.bookTitle,
    required this.shelfCode,
    required this.status,
    required this.checkedInAt,
    this.sellerName,
    this.lotStatus,
    this.checkedOutAt,
  });

  factory WarehouseItemDto.fromJson(Map<String, Object?> json) =>
      _$WarehouseItemDtoFromJson(json);

  final String id;
  final String consignmentId;
  final String bookTitle;
  final String? sellerName;
  final String shelfCode;
  final WarehouseStatus status;
  final LotStatus? lotStatus;
  final DateTime checkedInAt;
  final DateTime? checkedOutAt;

  Map<String, Object?> toJson() => _$WarehouseItemDtoToJson(this);
}
