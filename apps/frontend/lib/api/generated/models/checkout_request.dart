// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'payment_method.dart';

part 'checkout_request.g.dart';

@JsonSerializable()
class CheckoutRequest {
  const CheckoutRequest({
    required this.addressId,
    required this.paymentMethod,
    this.listingIds,
    this.note,
  });

  factory CheckoutRequest.fromJson(Map<String, Object?> json) =>
      _$CheckoutRequestFromJson(json);

  final int addressId;
  final PaymentMethod paymentMethod;
  final List<int>? listingIds;
  final String? note;

  Map<String, Object?> toJson() => _$CheckoutRequestToJson(this);
}
