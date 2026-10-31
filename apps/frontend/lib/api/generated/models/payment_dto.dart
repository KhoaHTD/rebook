// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payment_status.dart';

part 'payment_dto.g.dart';

@JsonSerializable()
class PaymentDto {
  const PaymentDto({
    required this.id,
    required this.gateway,
    required this.amount,
    required this.status,
    this.paymentUrl,
    this.expiresAt,
  });

  factory PaymentDto.fromJson(Map<String, Object?> json) =>
      _$PaymentDtoFromJson(json);

  final String id;

  /// VNPAY
  final String gateway;
  final int amount;
  final PaymentStatus status;
  final String? paymentUrl;
  final DateTime? expiresAt;

  Map<String, Object?> toJson() => _$PaymentDtoToJson(this);
}
