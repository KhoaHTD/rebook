// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'book_input.dart';

part 'consignment_request.g.dart';

@JsonSerializable()
class ConsignmentRequest {
  const ConsignmentRequest({
    required this.book,
    required this.expectedPrice,
    required this.story,
  });

  factory ConsignmentRequest.fromJson(Map<String, Object?> json) =>
      _$ConsignmentRequestFromJson(json);

  final BookInput book;
  final int expectedPrice;

  /// Câu chuyện / nguồn gốc
  final String story;

  Map<String, Object?> toJson() => _$ConsignmentRequestToJson(this);
}
