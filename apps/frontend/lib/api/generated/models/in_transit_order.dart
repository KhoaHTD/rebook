// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payment_method.dart';

part 'in_transit_order.g.dart';

@JsonSerializable()
class InTransitOrder {
  const InTransitOrder({
    this.orderId,
    this.code,
    this.shopId,
    this.shopName,
    this.buyerId,
    this.paymentMethod,
    this.total,
    this.trackingCode,
    this.shippedAt,
    this.overdue,
  });
  
  factory InTransitOrder.fromJson(Map<String, Object?> json) => _$InTransitOrderFromJson(json);
  
  final int? orderId;
  final String? code;
  final int? shopId;
  final String? shopName;
  final int? buyerId;
  final PaymentMethod? paymentMethod;
  final num? total;
  final String? trackingCode;
  final DateTime? shippedAt;
  final bool? overdue;

  Map<String, Object?> toJson() => _$InTransitOrderToJson(this);
}
