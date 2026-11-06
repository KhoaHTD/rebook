// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'inspecting_lot.dart';

part 'page_response_inspecting_lot.g.dart';

@JsonSerializable()
class PageResponseInspectingLot {
  const PageResponseInspectingLot({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseInspectingLot.fromJson(Map<String, Object?> json) =>
      _$PageResponseInspectingLotFromJson(json);

  final List<InspectingLot>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseInspectingLotToJson(this);
}
