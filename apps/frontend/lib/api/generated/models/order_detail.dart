// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'history_response.dart';
import 'order_item_response.dart';
import 'order_status.dart';
import 'order_type.dart';
import 'payment_method.dart';
import 'return_response.dart';

part 'order_detail.g.dart';

@JsonSerializable()
class OrderDetail {
  const OrderDetail({
    this.depositApplied,
    this.code,
    this.orderType,
    this.status,
    this.buyerId,
    this.shopId,
    this.shopName,
    this.lotId,
    this.items,
    this.subtotal,
    this.shippingFee,
    this.buyerPremium,
    this.id,
    this.total,
    this.amountDue,
    this.paymentMethod,
    this.paidAt,
    this.address,
    this.pickupAtWarehouse,
    this.trackingCode,
    this.note,
    this.cancelReason,
    this.canRequestReturn,
    this.secondChance,
    this.paymentDueAt,
    this.confirmDueAt,
    this.deliveredAt,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
    this.history,
    this.returnRequest,
    this.reviewed,
    this.canReview,
    this.cancelRequested,
  });

  factory OrderDetail.fromJson(Map<String, Object?> json) =>
      _$OrderDetailFromJson(json);

  final int? id;
  final String? code;
  final OrderType? orderType;
  final OrderStatus? status;
  final int? buyerId;
  final int? shopId;
  final String? shopName;
  final int? lotId;
  final List<OrderItemResponse>? items;
  final num? subtotal;
  final num? shippingFee;
  final num? buyerPremium;
  final num? depositApplied;
  final num? total;
  final num? amountDue;
  final PaymentMethod? paymentMethod;
  final DateTime? paidAt;
  final Map<String, dynamic>? address;
  final bool? pickupAtWarehouse;
  final String? trackingCode;
  final String? note;
  final String? cancelReason;
  final bool? cancelRequested;
  final bool? secondChance;
  final DateTime? paymentDueAt;
  final DateTime? confirmDueAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final List<HistoryResponse>? history;
  final ReturnResponse? returnRequest;
  final bool? reviewed;
  final bool? canReview;
  final bool? canRequestReturn;

  Map<String, Object?> toJson() => _$OrderDetailToJson(this);
}
