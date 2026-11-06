// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// Ai gây giao thất bại. BUYER = người mua từ chối nhận, sai địa chỉ, không liên lạc được
@JsonEnum()
enum DeliveryFault {
  @JsonValue('BUYER')
  buyer('BUYER'),
  @JsonValue('CARRIER')
  carrier('CARRIER'),
  @JsonValue('SHOP')
  shop('SHOP'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const DeliveryFault(this.json);

  factory DeliveryFault.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<DeliveryFault> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
