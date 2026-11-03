// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'shop_quote.dart';

part 'checkout_preview.g.dart';

@JsonSerializable()
class CheckoutPreview {
  const CheckoutPreview({
    this.shops,
    this.subtotal,
    this.shippingFee,
    this.total,
  });

  factory CheckoutPreview.fromJson(Map<String, Object?> json) =>
      _$CheckoutPreviewFromJson(json);

  final List<ShopQuote>? shops;
  final num? subtotal;
  final num? shippingFee;
  final num? total;

  Map<String, Object?> toJson() => _$CheckoutPreviewToJson(this);
}
