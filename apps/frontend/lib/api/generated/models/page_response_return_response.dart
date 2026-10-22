// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'return_response.dart';

part 'page_response_return_response.g.dart';

@JsonSerializable()
class PageResponseReturnResponse {
  const PageResponseReturnResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseReturnResponse.fromJson(Map<String, Object?> json) =>
      _$PageResponseReturnResponseFromJson(json);

  final List<ReturnResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseReturnResponseToJson(this);
}
