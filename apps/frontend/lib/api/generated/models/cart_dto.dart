// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cart_shop_group_dto.dart';

part 'cart_dto.g.dart';

@JsonSerializable()
class CartDto {
  const CartDto({
    required this.groups,
    required this.subtotal,
    required this.shippingTotal,
    required this.total,
  });

  factory CartDto.fromJson(Map<String, Object?> json) =>
      _$CartDtoFromJson(json);

  final List<CartShopGroupDto> groups;
  final int subtotal;
  final int shippingTotal;
  final int total;

  Map<String, Object?> toJson() => _$CartDtoToJson(this);
}
