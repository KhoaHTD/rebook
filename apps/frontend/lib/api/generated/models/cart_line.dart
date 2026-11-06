// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'cart_line.g.dart';

@JsonSerializable()
class CartLine {
  const CartLine({
    this.listingId,
    this.title,
    this.author,
    this.coverUrl,
    this.price,
    this.quantity,
    this.stock,
    this.available,
    this.lineTotal,
  });

  factory CartLine.fromJson(Map<String, Object?> json) =>
      _$CartLineFromJson(json);

  final int? listingId;
  final String? title;
  final String? author;
  final String? coverUrl;
  final num? price;
  final int? quantity;
  final int? stock;
  final bool? available;
  final num? lineTotal;

  Map<String, Object?> toJson() => _$CartLineToJson(this);
}
