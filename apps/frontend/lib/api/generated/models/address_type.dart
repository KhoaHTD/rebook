// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Loại địa chỉ: nhà riêng / văn phòng (màn sửa địa chỉ).
@JsonEnum()
enum AddressType {
  @JsonValue('HOME')
  home('HOME'),
  @JsonValue('OFFICE')
  office('OFFICE'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const AddressType(this.json);

  factory AddressType.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<AddressType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
