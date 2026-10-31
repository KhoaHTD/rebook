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
    required this.bankName,
    required this.bankAccount,
    required this.bankHolder,
    this.description,
  });

  factory ShopRequest.fromJson(Map<String, Object?> json) =>
      _$ShopRequestFromJson(json);

  final String name;
  final String? description;
  final String pickupAddress;
  final String bankName;
  final String bankAccount;
  final String bankHolder;

  Map<String, Object?> toJson() => _$ShopRequestToJson(this);
}
