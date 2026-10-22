// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'listing_dto.dart';

part 'listing_page.g.dart';

@JsonSerializable()
class ListingPage {
  const ListingPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  factory ListingPage.fromJson(Map<String, Object?> json) =>
      _$ListingPageFromJson(json);

  final List<ListingDto> items;
  final int page;
  final int size;
  final int total;

  Map<String, Object?> toJson() => _$ListingPageToJson(this);
}
