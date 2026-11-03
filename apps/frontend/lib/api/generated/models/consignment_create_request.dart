// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_request.dart';

part 'consignment_create_request.g.dart';

@JsonSerializable()
class ConsignmentCreateRequest {
  const ConsignmentCreateRequest({
    required this.book,
    required this.expectedPrice,
    this.provenance,
  });

  factory ConsignmentCreateRequest.fromJson(Map<String, Object?> json) =>
      _$ConsignmentCreateRequestFromJson(json);

  final BookRequest book;
  final num expectedPrice;
  final String? provenance;

  Map<String, Object?> toJson() => _$ConsignmentCreateRequestToJson(this);
}
