// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'withdraw_status.dart';

part 'withdraw_response.g.dart';

@JsonSerializable()
class WithdrawResponse {
  const WithdrawResponse({
    this.id,
    this.userId,
    this.amount,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
    this.status,
    this.note,
    this.processedAt,
    this.createdAt,
  });

  factory WithdrawResponse.fromJson(Map<String, Object?> json) =>
      _$WithdrawResponseFromJson(json);

  final int? id;
  final int? userId;
  final num? amount;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;
  final WithdrawStatus? status;
  final String? note;
  final DateTime? processedAt;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$WithdrawResponseToJson(this);
}
