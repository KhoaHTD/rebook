// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'warehouse_response.dart';

part 'page_response_warehouse_response.g.dart';

@JsonSerializable()
class PageResponseWarehouseResponse {
  const PageResponseWarehouseResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseWarehouseResponse.fromJson(Map<String, Object?> json) =>
      _$PageResponseWarehouseResponseFromJson(json);

  final List<WarehouseResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseWarehouseResponseToJson(this);
}
