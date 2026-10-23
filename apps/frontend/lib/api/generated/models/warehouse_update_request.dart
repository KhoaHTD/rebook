// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'warehouse_status.dart';

part 'warehouse_update_request.g.dart';

@JsonSerializable()
class WarehouseUpdateRequest {
  const WarehouseUpdateRequest({this.shelfCode, this.status});

  factory WarehouseUpdateRequest.fromJson(Map<String, Object?> json) =>
      _$WarehouseUpdateRequestFromJson(json);

  final String? shelfCode;
  final WarehouseStatus? status;

  Map<String, Object?> toJson() => _$WarehouseUpdateRequestToJson(this);
}
