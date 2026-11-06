// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'delivery_fault.dart';

part 'delivery_failed_request.g.dart';

@JsonSerializable()
class DeliveryFailedRequest {
  const DeliveryFailedRequest({required this.reason, this.fault});

  factory DeliveryFailedRequest.fromJson(Map<String, Object?> json) =>
      _$DeliveryFailedRequestFromJson(json);

  final String reason;
  final DeliveryFault? fault;

  Map<String, Object?> toJson() => _$DeliveryFailedRequestToJson(this);
}
