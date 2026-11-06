// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'return_shipment_request.g.dart';

@JsonSerializable()
class ReturnShipmentRequest {
  const ReturnShipmentRequest({required this.trackingCode});

  factory ReturnShipmentRequest.fromJson(Map<String, Object?> json) =>
      _$ReturnShipmentRequestFromJson(json);

  final String trackingCode;

  Map<String, Object?> toJson() => _$ReturnShipmentRequestToJson(this);
}
