// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'in_transit_order.dart';

part 'page_response_in_transit_order.g.dart';

@JsonSerializable()
class PageResponseInTransitOrder {
  const PageResponseInTransitOrder({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });
  
  factory PageResponseInTransitOrder.fromJson(Map<String, Object?> json) => _$PageResponseInTransitOrderFromJson(json);
  
  final List<InTransitOrder>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseInTransitOrderToJson(this);
}
