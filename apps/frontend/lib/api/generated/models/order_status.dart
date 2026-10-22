// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum OrderStatus {
  @JsonValue('PENDING_PAYMENT')
  pendingPayment('PENDING_PAYMENT'),
  @JsonValue('PENDING_CONFIRM')
  pendingConfirm('PENDING_CONFIRM'),
  @JsonValue('PREPARING')
  preparing('PREPARING'),
  @JsonValue('SHIPPING')
  shipping('SHIPPING'),
  @JsonValue('DELIVERED')
  delivered('DELIVERED'),
  @JsonValue('RETURN_REQUESTED')
  returnRequested('RETURN_REQUESTED'),
  @JsonValue('COMPLETED')
  completed('COMPLETED'),
  @JsonValue('CANCELLED')
  cancelled('CANCELLED'),
  @JsonValue('RETURNED')
  returned('RETURNED'),
  @JsonValue('FAILED_DELIVERY')
  failedDelivery('FAILED_DELIVERY'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const OrderStatus(this.json);

  factory OrderStatus.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<OrderStatus> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
