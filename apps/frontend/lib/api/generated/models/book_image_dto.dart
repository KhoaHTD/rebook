// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'image_source.dart';

part 'book_image_dto.g.dart';

@JsonSerializable()
class BookImageDto {
  const BookImageDto({
    required this.id,
    required this.url,
    required this.sortOrder,
    required this.source,
  });

  factory BookImageDto.fromJson(Map<String, Object?> json) =>
      _$BookImageDtoFromJson(json);

  final String id;
  final String url;
  final int sortOrder;
  final ImageSource source;

  Map<String, Object?> toJson() => _$BookImageDtoToJson(this);
}
