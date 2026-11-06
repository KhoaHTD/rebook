// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_response.dart';

part 'category_response.g.dart';

@JsonSerializable()
class CategoryResponse {
  const CategoryResponse({
    this.id,
    this.name,
    this.slug,
    this.parentId,
    this.sortOrder,
    this.children,
  });

  factory CategoryResponse.fromJson(Map<String, Object?> json) =>
      _$CategoryResponseFromJson(json);

  final int? id;
  final String? name;
  final String? slug;
  final int? parentId;
  final int? sortOrder;
  final List<CategoryResponse>? children;

  Map<String, Object?> toJson() => _$CategoryResponseToJson(this);
}
