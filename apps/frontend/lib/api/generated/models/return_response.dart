// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'return_reason.dart';
import 'return_status.dart';

part 'return_response.g.dart';

@JsonSerializable()
class ReturnResponse {
  const ReturnResponse({
    this.id,
    this.orderId,
    this.reason,
    this.description,
    this.images,
    this.status,
    this.sellerNote,
    this.resolution,
    this.createdAt,
  });

  factory ReturnResponse.fromJson(Map<String, Object?> json) =>
      _$ReturnResponseFromJson(json);

  final int? id;
  final int? orderId;
  final ReturnReason? reason;
  final String? description;
  final List<String>? images;
  final ReturnStatus? status;
  final String? sellerNote;
  final String? resolution;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$ReturnResponseToJson(this);
}
