// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'order_item_dto.g.dart';

@JsonSerializable()
class OrderItemDto {
  const OrderItemDto({
    required this.id,
    required this.titleSnapshot,
    required this.unitPrice,
    required this.quantity,
    this.listingId,
    this.lotId,
    this.imageUrl,
  });

  factory OrderItemDto.fromJson(Map<String, Object?> json) =>
      _$OrderItemDtoFromJson(json);

  final String id;
  final String? listingId;
  final String? lotId;
  final String titleSnapshot;
  final String? imageUrl;
  final int unitPrice;
  final int quantity;

  Map<String, Object?> toJson() => _$OrderItemDtoToJson(this);
}
