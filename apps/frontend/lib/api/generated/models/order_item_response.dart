// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'order_item_response.g.dart';

@JsonSerializable()
class OrderItemResponse {
  const OrderItemResponse({
    this.id,
    this.listingId,
    this.lotId,
    this.title,
    this.imageUrl,
    this.unitPrice,
    this.quantity,
    this.lineTotal,
  });

  factory OrderItemResponse.fromJson(Map<String, Object?> json) =>
      _$OrderItemResponseFromJson(json);

  final int? id;
  final int? listingId;
  final int? lotId;
  final String? title;
  final String? imageUrl;
  final num? unitPrice;
  final int? quantity;
  final num? lineTotal;

  Map<String, Object?> toJson() => _$OrderItemResponseToJson(this);
}
