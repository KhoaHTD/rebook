// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'ship_request.g.dart';

@JsonSerializable()
class ShipRequest {
  const ShipRequest({this.trackingCode});

  factory ShipRequest.fromJson(Map<String, Object?> json) =>
      _$ShipRequestFromJson(json);

  final String? trackingCode;

  Map<String, Object?> toJson() => _$ShipRequestToJson(this);
}
