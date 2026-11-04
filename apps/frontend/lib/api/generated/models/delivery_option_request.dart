// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'delivery_option_request.g.dart';

@JsonSerializable()
class DeliveryOptionRequest {
  const DeliveryOptionRequest({this.addressId, this.pickupAtWarehouse});

  factory DeliveryOptionRequest.fromJson(Map<String, Object?> json) =>
      _$DeliveryOptionRequestFromJson(json);

  final int? addressId;
  final bool? pickupAtWarehouse;

  Map<String, Object?> toJson() => _$DeliveryOptionRequestToJson(this);
}
