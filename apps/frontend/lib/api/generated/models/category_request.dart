// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'category_request.g.dart';

@JsonSerializable()
class CategoryRequest {
  const CategoryRequest({
    required this.name,
    required this.slug,
    this.parentId,
    this.sortOrder,
  });

  factory CategoryRequest.fromJson(Map<String, Object?> json) =>
      _$CategoryRequestFromJson(json);

  final String name;
  final String slug;
  final int? parentId;
  final int? sortOrder;

  Map<String, Object?> toJson() => _$CategoryRequestToJson(this);
}
