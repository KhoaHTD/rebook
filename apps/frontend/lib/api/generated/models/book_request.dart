// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_grade.dart';

part 'book_request.g.dart';

@JsonSerializable()
class BookRequest {
  const BookRequest({
    required this.title,
    required this.author,
    required this.categoryId,
    required this.conditionGrade,
    required this.weightGram,
    required this.imageUrls,
    this.publisher,
    this.publishYear,
    this.isbn,
    this.language,
    this.pages,
    this.description,
  });

  factory BookRequest.fromJson(Map<String, Object?> json) =>
      _$BookRequestFromJson(json);

  final String title;
  final String author;
  final String? publisher;
  final int? publishYear;
  final String? isbn;
  final String? language;
  final int? pages;
  final int categoryId;
  final ConditionGrade conditionGrade;
  final String? description;
  final int weightGram;
  final List<String> imageUrls;

  Map<String, Object?> toJson() => _$BookRequestToJson(this);
}
