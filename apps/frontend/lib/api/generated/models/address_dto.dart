// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'address_type.dart';

part 'address_dto.g.dart';

@JsonSerializable()
class AddressDto {
  const AddressDto({
    required this.id,
    required this.receiver,
    required this.phone,
    required this.province,
    required this.district,
    required this.ward,
    required this.detail,
    required this.isDefault,
    this.latitude,
    this.longitude,
    this.addressType,
  });

  factory AddressDto.fromJson(Map<String, Object?> json) =>
      _$AddressDtoFromJson(json);

  final String id;
  final String receiver;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String detail;
  final bool isDefault;

  /// Vị trí người dùng ghim trên bản đồ (SRS 9 — addresses).
  final double? latitude;
  final double? longitude;
  final AddressType? addressType;

  Map<String, Object?> toJson() => _$AddressDtoToJson(this);
}
