// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lot_public.dart';

part 'page_response_lot_public.g.dart';

@JsonSerializable()
class PageResponseLotPublic {
  const PageResponseLotPublic({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseLotPublic.fromJson(Map<String, Object?> json) =>
      _$PageResponseLotPublicFromJson(json);

  final List<LotPublic>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseLotPublicToJson(this);
}
