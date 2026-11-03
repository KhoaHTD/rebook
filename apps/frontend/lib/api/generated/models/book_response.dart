// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'condition_grade.dart';
import 'image_response.dart';

part 'book_response.g.dart';

@JsonSerializable()
class BookResponse {
  const BookResponse({
    this.id,
    this.title,
    this.author,
    this.publisher,
    this.publishYear,
    this.isbn,
    this.language,
    this.pages,
    this.categoryId,
    this.conditionGrade,
    this.description,
    this.weightGram,
    this.coverUrl,
    this.images,
  });

  factory BookResponse.fromJson(Map<String, Object?> json) =>
      _$BookResponseFromJson(json);

  final int? id;
  final String? title;
  final String? author;
  final String? publisher;
  final int? publishYear;
  final String? isbn;
  final String? language;
  final int? pages;
  final int? categoryId;
  final ConditionGrade? conditionGrade;
  final String? description;
  final int? weightGram;
  final String? coverUrl;
  final List<ImageResponse>? images;

  Map<String, Object?> toJson() => _$BookResponseToJson(this);
}
