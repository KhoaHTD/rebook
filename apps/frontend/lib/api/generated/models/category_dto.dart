// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'category_dto.g.dart';

@JsonSerializable()
class CategoryDto {
  const CategoryDto({required this.id, required this.name, this.parentId});

  factory CategoryDto.fromJson(Map<String, Object?> json) =>
      _$CategoryDtoFromJson(json);

  final String id;
  final String name;
  final String? parentId;

  Map<String, Object?> toJson() => _$CategoryDtoToJson(this);
}
