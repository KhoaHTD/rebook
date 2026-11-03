// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_status.dart';

part 'history_response.g.dart';

@JsonSerializable()
class HistoryResponse {
  const HistoryResponse({
    this.fromStatus,
    this.toStatus,
    this.actorId,
    this.note,
    this.createdAt,
  });

  factory HistoryResponse.fromJson(Map<String, Object?> json) =>
      _$HistoryResponseFromJson(json);

  final OrderStatus? fromStatus;
  final OrderStatus? toStatus;
  final int? actorId;
  final String? note;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$HistoryResponseToJson(this);
}
