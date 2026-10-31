// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'address_request.g.dart';

@JsonSerializable()
class AddressRequest {
  const AddressRequest({
    required this.receiver,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.detail,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  factory AddressRequest.fromJson(Map<String, Object?> json) =>
      _$AddressRequestFromJson(json);

  final String receiver;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String detail;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  Map<String, Object?> toJson() => _$AddressRequestToJson(this);
}
