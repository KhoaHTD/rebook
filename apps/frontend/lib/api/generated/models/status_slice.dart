// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_status.dart';

part 'status_slice.g.dart';

@JsonSerializable()
class StatusSlice {
  const StatusSlice({this.status, this.count});

  factory StatusSlice.fromJson(Map<String, Object?> json) =>
      _$StatusSliceFromJson(json);

  final OrderStatus? status;
  final int? count;

  Map<String, Object?> toJson() => _$StatusSliceToJson(this);
}
