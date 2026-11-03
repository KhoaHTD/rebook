// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'stock_request.g.dart';

@JsonSerializable()
class StockRequest {
  const StockRequest({required this.stock});

  factory StockRequest.fromJson(Map<String, Object?> json) =>
      _$StockRequestFromJson(json);

  final int stock;

  Map<String, Object?> toJson() => _$StockRequestToJson(this);
}
