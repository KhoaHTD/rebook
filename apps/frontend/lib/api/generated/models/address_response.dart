// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'address_response.g.dart';

@JsonSerializable()
class AddressResponse {
  const AddressResponse({
    this.id,
    this.receiverName,
    this.phone,
    this.province,
    this.district,
    this.ward,
    this.detail,
    this.isDefault,
  });

  factory AddressResponse.fromJson(Map<String, Object?> json) =>
      _$AddressResponseFromJson(json);

  final int? id;
  final String? receiverName;
  final String? phone;
  final String? province;
  final String? district;
  final String? ward;
  final String? detail;
  final bool? isDefault;

  Map<String, Object?> toJson() => _$AddressResponseToJson(this);
}
