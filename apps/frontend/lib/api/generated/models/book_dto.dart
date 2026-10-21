// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_condition.dart';

part 'book_dto.g.dart';

@JsonSerializable()
class BookDto {
  const BookDto({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.price,
    required this.sellerName,
    this.imageUrl,
    this.description,
  });

  factory BookDto.fromJson(Map<String, Object?> json) =>
      _$BookDtoFromJson(json);

  final String id;
  final String title;
  final String author;
  final BookCondition condition;

  /// Giá theo VND
  final int price;
  final String? imageUrl;
  final String sellerName;
  final String? description;

  Map<String, Object?> toJson() => _$BookDtoToJson(this);
}
