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
    this.resolvedBy,
    this.resolvedAt,
    this.respondBy,
  });

  factory ReturnRequestDto.fromJson(Map<String, Object?> json) =>
      _$ReturnRequestDtoFromJson(json);

  final String id;
  final String reason;
  final List<String> imageUrls;
  final ReturnStatus status;
  final String? resolution;

  /// Tên Admin phân xử.
  final String? resolvedBy;
  final DateTime? resolvedAt;

  /// Hạn shop / kho trả lời (SRS 4.4). Quá hạn thì yêu cầu tự chuyển Admin phân xử (status ESCALATED).
  final DateTime? respondBy;

  Map<String, Object?> toJson() => _$ReturnRequestDtoToJson(this);
}
