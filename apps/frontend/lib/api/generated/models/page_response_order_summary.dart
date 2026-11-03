// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_summary.dart';

part 'page_response_order_summary.g.dart';

@JsonSerializable()
class PageResponseOrderSummary {
  const PageResponseOrderSummary({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseOrderSummary.fromJson(Map<String, Object?> json) =>
      _$PageResponseOrderSummaryFromJson(json);

  final List<OrderSummary>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseOrderSummaryToJson(this);
}
