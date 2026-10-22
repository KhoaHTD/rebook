// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'shelf_request.g.dart';

@JsonSerializable()
class ShelfRequest {
  const ShelfRequest({required this.shelfCode});

  factory ShelfRequest.fromJson(Map<String, Object?> json) =>
      _$ShelfRequestFromJson(json);

  final String shelfCode;

  Map<String, Object?> toJson() => _$ShelfRequestToJson(this);
}
