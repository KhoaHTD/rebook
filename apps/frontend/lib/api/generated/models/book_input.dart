// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_grade.dart';

part 'book_input.g.dart';

@JsonSerializable()
class BookInput {
  const BookInput({
    required this.title,
    required this.author,
    required this.conditionGrade,
    required this.imageUrls,
    this.publisher,
    this.publishYear,
    this.isbn,
    this.language,
    this.pages,
    this.categoryId,
    this.description,
    this.weightGram,
  });

  factory BookInput.fromJson(Map<String, Object?> json) =>
      _$BookInputFromJson(json);

  final String title;
  final String author;
  final String? publisher;
  final int? publishYear;
  final String? isbn;
  final String? language;
  final int? pages;
  final String? categoryId;
  final ConditionGrade conditionGrade;
  final String? description;
  final int? weightGram;
  final List<String> imageUrls;

  Map<String, Object?> toJson() => _$BookInputToJson(this);
}
