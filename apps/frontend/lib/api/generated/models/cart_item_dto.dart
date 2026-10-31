// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'listing_dto.dart';

part 'cart_item_dto.g.dart';

@JsonSerializable()
class CartItemDto {
  const CartItemDto({
    required this.id,
    required this.listing,
    required this.quantity,
  });

  factory CartItemDto.fromJson(Map<String, Object?> json) =>
      _$CartItemDtoFromJson(json);

  final String id;
  final ListingDto listing;
  final int quantity;

  Map<String, Object?> toJson() => _$CartItemDtoToJson(this);
}
