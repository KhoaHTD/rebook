// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'return_status.dart';

part 'return_request_dto.g.dart';

@JsonSerializable()
class ReturnRequestDto {
  const ReturnRequestDto({
    required this.id,
    required this.reason,
    required this.imageUrls,
    required this.status,
    this.resolution,
  });

  factory ReturnRequestDto.fromJson(Map<String, Object?> json) =>
      _$ReturnRequestDtoFromJson(json);

  final String id;
  final String reason;
  final List<String> imageUrls;
  final ReturnStatus status;
  final String? resolution;

  Map<String, Object?> toJson() => _$ReturnRequestDtoToJson(this);
}
