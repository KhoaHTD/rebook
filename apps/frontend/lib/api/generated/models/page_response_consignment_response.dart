// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'consignment_response.dart';

part 'page_response_consignment_response.g.dart';

@JsonSerializable()
class PageResponseConsignmentResponse {
  const PageResponseConsignmentResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseConsignmentResponse.fromJson(Map<String, Object?> json) =>
      _$PageResponseConsignmentResponseFromJson(json);

  final List<ConsignmentResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() =>
      _$PageResponseConsignmentResponseToJson(this);
}
