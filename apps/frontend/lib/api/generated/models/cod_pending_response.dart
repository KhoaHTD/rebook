// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'order_status.dart';

part 'cod_pending_response.g.dart';

@JsonSerializable()
class CodPendingResponse {
  const CodPendingResponse({
    this.orderId,
    this.code,
    this.status,
    this.total,
    this.deliveredAt,
    this.refundPending,
  });
  
  factory CodPendingResponse.fromJson(Map<String, Object?> json) => _$CodPendingResponseFromJson(json);
  
  final int? orderId;
  final String? code;
  final OrderStatus? status;
  final num? total;
  final DateTime? deliveredAt;
  final bool? refundPending;

  Map<String, Object?> toJson() => _$CodPendingResponseToJson(this);
}
