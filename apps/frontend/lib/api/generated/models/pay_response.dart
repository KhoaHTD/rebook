// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_summary.dart';
import 'payment_response.dart';

part 'pay_response.g.dart';

@JsonSerializable()
class PayResponse {
  const PayResponse({this.order, this.payment});

  factory PayResponse.fromJson(Map<String, Object?> json) =>
      _$PayResponseFromJson(json);

  final OrderSummary? order;
  final PaymentResponse? payment;

  Map<String, Object?> toJson() => _$PayResponseToJson(this);
}
