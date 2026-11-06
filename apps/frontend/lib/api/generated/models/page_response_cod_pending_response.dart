// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cod_pending_response.dart';

part 'page_response_cod_pending_response.g.dart';

@JsonSerializable()
class PageResponseCodPendingResponse {
  const PageResponseCodPendingResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });
  
  factory PageResponseCodPendingResponse.fromJson(Map<String, Object?> json) => _$PageResponseCodPendingResponseFromJson(json);
  
  final List<CodPendingResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseCodPendingResponseToJson(this);
}
