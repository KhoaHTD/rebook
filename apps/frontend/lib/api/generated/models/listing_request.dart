// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_request.dart';

part 'listing_request.g.dart';

@JsonSerializable()
class ListingRequest {
  const ListingRequest({
    required this.book,
    required this.price,
    required this.stock,
  });

  factory ListingRequest.fromJson(Map<String, Object?> json) =>
      _$ListingRequestFromJson(json);

  final BookRequest book;
  final num price;
  final int stock;

  Map<String, Object?> toJson() => _$ListingRequestToJson(this);
}
