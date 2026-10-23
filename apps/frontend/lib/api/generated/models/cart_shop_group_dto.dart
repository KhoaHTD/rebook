// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cart_item_dto.dart';
import 'shop_summary_dto.dart';

part 'cart_shop_group_dto.g.dart';

@JsonSerializable()
class CartShopGroupDto {
  const CartShopGroupDto({
    required this.shop,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
  });

  factory CartShopGroupDto.fromJson(Map<String, Object?> json) =>
      _$CartShopGroupDtoFromJson(json);

  final ShopSummaryDto shop;
  final List<CartItemDto> items;
  final int subtotal;
  final int shippingFee;

  Map<String, Object?> toJson() => _$CartShopGroupDtoToJson(this);
}
