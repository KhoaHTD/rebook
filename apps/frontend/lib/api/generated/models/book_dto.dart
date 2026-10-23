// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_image_dto.dart';
import 'condition_grade.dart';

part 'book_dto.g.dart';

@JsonSerializable()
class BookDto {
  const BookDto({
    required this.id,
    required this.title,
    required this.author,
    required this.conditionGrade,
    required this.images,
    this.publisher,
    this.publishYear,
    this.isbn,
    this.language,
    this.pages,
    this.categoryId,
    this.categoryName,
    this.description,
    this.weightGram,
  });

  factory BookDto.fromJson(Map<String, Object?> json) =>
      _$BookDtoFromJson(json);

  final String id;
  final String title;
  final String author;
  final String? publisher;
  final int? publishYear;
  final String? isbn;
  final String? language;
  final int? pages;
  final String? categoryId;
  final String? categoryName;
  final ConditionGrade conditionGrade;
  final String? description;
  final int? weightGram;
  final List<BookImageDto> images;

  Map<String, Object?> toJson() => _$BookDtoToJson(this);
}
