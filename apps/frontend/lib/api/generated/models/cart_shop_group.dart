// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cart_line.dart';

part 'cart_shop_group.g.dart';

@JsonSerializable()
class CartShopGroup {
  const CartShopGroup({
    this.shopId,
    this.shopName,
    this.shopProvince,
    this.items,
    this.subtotal,
  });

  factory CartShopGroup.fromJson(Map<String, Object?> json) =>
      _$CartShopGroupFromJson(json);

  final int? shopId;
  final String? shopName;
  final String? shopProvince;
  final List<CartLine>? items;
  final num? subtotal;

  Map<String, Object?> toJson() => _$CartShopGroupToJson(this);
}
