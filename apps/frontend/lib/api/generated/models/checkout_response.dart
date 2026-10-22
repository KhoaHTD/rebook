// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_summary.dart';
import 'payment_response.dart';

part 'checkout_response.g.dart';

@JsonSerializable()
class CheckoutResponse {
  const CheckoutResponse({this.orders, this.payment});

  factory CheckoutResponse.fromJson(Map<String, Object?> json) =>
      _$CheckoutResponseFromJson(json);

  final List<OrderSummary>? orders;
  final PaymentResponse? payment;

  Map<String, Object?> toJson() => _$CheckoutResponseToJson(this);
}
