// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payment_method.dart';

part 'pay_order_request.g.dart';

@JsonSerializable()
class PayOrderRequest {
  const PayOrderRequest({
    required this.paymentMethod,
    this.addressId,
    this.pickupAtWarehouse,
  });

  factory PayOrderRequest.fromJson(Map<String, Object?> json) =>
      _$PayOrderRequestFromJson(json);

  final PaymentMethod paymentMethod;

  /// Bắt buộc với hóa đơn lô đấu giá giao tận nơi
  final String? addressId;
  final bool? pickupAtWarehouse;

  Map<String, Object?> toJson() => _$PayOrderRequestToJson(this);
}
