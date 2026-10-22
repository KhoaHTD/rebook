// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_status.dart';

part 'order_status_change_dto.g.dart';

@JsonSerializable()
class OrderStatusChangeDto {
  const OrderStatusChangeDto({
    required this.toStatus,
    required this.createdAt,
    this.fromStatus,
    this.note,
  });

  factory OrderStatusChangeDto.fromJson(Map<String, Object?> json) =>
      _$OrderStatusChangeDtoFromJson(json);

  final OrderStatus? fromStatus;
  final OrderStatus toStatus;
  final String? note;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$OrderStatusChangeDtoToJson(this);
}
