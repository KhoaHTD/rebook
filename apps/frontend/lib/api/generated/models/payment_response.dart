// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payment_method.dart';
import 'payment_purpose.dart';
import 'payment_status.dart';

part 'payment_response.g.dart';

@JsonSerializable()
class PaymentResponse {
  const PaymentResponse({
    this.id,
    this.code,
    this.purpose,
    this.method,
    this.amount,
    this.status,
    this.paymentUrl,
    this.simulateAvailable,
    this.expiresAt,
    this.paidAt,
  });

  factory PaymentResponse.fromJson(Map<String, Object?> json) =>
      _$PaymentResponseFromJson(json);

  final int? id;
  final String? code;
  final PaymentPurpose? purpose;
  final PaymentMethod? method;
  final num? amount;
  final PaymentStatus? status;
  final String? paymentUrl;
  final bool? simulateAvailable;
  final DateTime? expiresAt;
  final DateTime? paidAt;

  Map<String, Object?> toJson() => _$PaymentResponseToJson(this);
}
