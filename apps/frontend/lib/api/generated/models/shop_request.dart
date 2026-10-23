// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shop_request.g.dart';

@JsonSerializable()
class ShopRequest {
  const ShopRequest({
    required this.name,
    required this.pickupAddress,
    required this.pickupProvince,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountHolder,
    this.description,
  });

  factory ShopRequest.fromJson(Map<String, Object?> json) =>
      _$ShopRequestFromJson(json);

  final String name;
  final String? description;
  final String pickupAddress;
  final String pickupProvince;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountHolder;

  Map<String, Object?> toJson() => _$ShopRequestToJson(this);
}
