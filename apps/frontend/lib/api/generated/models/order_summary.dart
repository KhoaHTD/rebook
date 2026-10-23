// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_status.dart';
import 'order_type.dart';
import 'payment_method.dart';

part 'order_summary.g.dart';

@JsonSerializable()
class OrderSummary {
  const OrderSummary({
    this.id,
    this.code,
    this.orderType,
    this.status,
    this.shopId,
    this.shopName,
    this.buyerId,
    this.itemCount,
    this.firstItemTitle,
    this.coverUrl,
    this.total,
    this.amountDue,
    this.paymentMethod,
    this.paid,
    this.cancelRequested,
    this.paymentDueAt,
    this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, Object?> json) =>
      _$OrderSummaryFromJson(json);

  final int? id;
  final String? code;
  final OrderType? orderType;
  final OrderStatus? status;
  final int? shopId;
  final String? shopName;
  final int? buyerId;
  final int? itemCount;
  final String? firstItemTitle;
  final String? coverUrl;
  final num? total;
  final num? amountDue;
  final PaymentMethod? paymentMethod;
  final bool? paid;
  final bool? cancelRequested;
  final DateTime? paymentDueAt;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$OrderSummaryToJson(this);
}
