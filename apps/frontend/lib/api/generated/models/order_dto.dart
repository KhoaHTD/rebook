// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'address_dto.dart';
import 'order_item_dto.dart';
import 'order_status.dart';
import 'order_status_change_dto.dart';
import 'order_type.dart';
import 'payment_method.dart';
import 'return_request_dto.dart';
import 'review_dto.dart';
import 'shop_summary_dto.dart';

part 'order_dto.g.dart';

@JsonSerializable()
class OrderDto {
  const OrderDto({
    required this.id,
    required this.code,
    required this.orderType,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    required this.buyerPremium,
    required this.depositApplied,
    required this.total,
    required this.createdAt,
    required this.history,
    required this.canReview,
    this.shop,
    this.buyerName,
    this.paymentMethod,
    this.address,
    this.pickupAtWarehouse,
    this.trackingCode,
    this.paymentDeadline,
    this.confirmDeadline,
    this.complaintDeadline,
    this.cancelRequested,
    this.review,
    this.returnRequest,
  });

  factory OrderDto.fromJson(Map<String, Object?> json) =>
      _$OrderDtoFromJson(json);

  final String id;
  final String code;
  final OrderType orderType;
  final OrderStatus status;
  final ShopSummaryDto? shop;
  final String? buyerName;
  final List<OrderItemDto> items;
  final int subtotal;
  final int shippingFee;
  final int buyerPremium;
  final int depositApplied;
  final int total;
  final PaymentMethod? paymentMethod;
  final AddressDto? address;
  final bool? pickupAtWarehouse;
  final String? trackingCode;
  final DateTime? paymentDeadline;
  final DateTime? confirmDeadline;
  final DateTime? complaintDeadline;
  final bool? cancelRequested;
  final DateTime createdAt;
  final List<OrderStatusChangeDto> history;
  final bool canReview;
  final ReviewDto? review;
  final ReturnRequestDto? returnRequest;

  Map<String, Object?> toJson() => _$OrderDtoToJson(this);
}
