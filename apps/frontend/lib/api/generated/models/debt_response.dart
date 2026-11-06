// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'debt_status.dart';
import 'debt_type.dart';

part 'debt_response.g.dart';

@JsonSerializable()
class DebtResponse {
  const DebtResponse({
    this.id,
    this.type,
    this.amount,
    this.paidAmount,
    this.remaining,
    this.status,
    this.note,
    this.createdAt,
    this.settledAt,
  });

  factory DebtResponse.fromJson(Map<String, Object?> json) =>
      _$DebtResponseFromJson(json);

  final int? id;
  final DebtType? type;
  final num? amount;
  final num? paidAmount;
  final num? remaining;
  final DebtStatus? status;
  final String? note;
  final DateTime? createdAt;
  final DateTime? settledAt;

  Map<String, Object?> toJson() => _$DebtResponseToJson(this);
}
