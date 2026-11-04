// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shop_quote.g.dart';

@JsonSerializable()
class ShopQuote {
  const ShopQuote({
    this.shopId,
    this.shopName,
    this.subtotal,
    this.shippingFee,
    this.total,
  });

  factory ShopQuote.fromJson(Map<String, Object?> json) =>
      _$ShopQuoteFromJson(json);

  final int? shopId;
  final String? shopName;
  final num? subtotal;
  final num? shippingFee;
  final num? total;

  Map<String, Object?> toJson() => _$ShopQuoteToJson(this);
}
