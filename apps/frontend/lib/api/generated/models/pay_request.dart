// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payment_method.dart';

part 'pay_request.g.dart';

@JsonSerializable()
class PayRequest {
  const PayRequest({required this.method});

  factory PayRequest.fromJson(Map<String, Object?> json) =>
      _$PayRequestFromJson(json);

  final PaymentMethod method;

  Map<String, Object?> toJson() => _$PayRequestToJson(this);
}
