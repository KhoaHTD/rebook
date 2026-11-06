// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shop_response.g.dart';

@JsonSerializable()
class ShopResponse {
  const ShopResponse({
    this.id,
    this.ownerId,
    this.name,
    this.description,
    this.pickupProvince,
    this.pickupAddress,
    this.ratingAvg,
    this.ratingCount,
    this.trusted,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.createdAt,
  });

  factory ShopResponse.fromJson(Map<String, Object?> json) =>
      _$ShopResponseFromJson(json);

  final int? id;
  final int? ownerId;
  final String? name;
  final String? description;
  final String? pickupProvince;
  final String? pickupAddress;
  final num? ratingAvg;
  final int? ratingCount;
  final bool? trusted;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$ShopResponseToJson(this);
}
