// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payment_method.dart';

part 'checkout_request.g.dart';

@JsonSerializable()
class CheckoutRequest {
  const CheckoutRequest({
    required this.addressId,
    required this.paymentMethod,
    this.cartItemIds,
    this.note,
  });

  factory CheckoutRequest.fromJson(Map<String, Object?> json) =>
      _$CheckoutRequestFromJson(json);

  final String addressId;
  final PaymentMethod paymentMethod;

  /// Bỏ trống = cả giỏ
  final List<String>? cartItemIds;
  final String? note;

  Map<String, Object?> toJson() => _$CheckoutRequestToJson(this);
}
