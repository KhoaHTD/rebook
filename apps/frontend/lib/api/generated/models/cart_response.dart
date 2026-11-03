// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cart_shop_group.dart';

part 'cart_response.g.dart';

@JsonSerializable()
class CartResponse {
  const CartResponse({this.shops, this.totalQuantity, this.subtotal});

  factory CartResponse.fromJson(Map<String, Object?> json) =>
      _$CartResponseFromJson(json);

  final List<CartShopGroup>? shops;
  final int? totalQuantity;
  final num? subtotal;

  Map<String, Object?> toJson() => _$CartResponseToJson(this);
}
