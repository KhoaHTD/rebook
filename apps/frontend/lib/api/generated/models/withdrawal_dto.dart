// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'withdrawal_receipt_dto.dart';
import 'withdrawal_status.dart';

part 'withdrawal_dto.g.dart';

@JsonSerializable()
class WithdrawalDto {
  const WithdrawalDto({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.userName,
    this.receipt,
  });

  factory WithdrawalDto.fromJson(Map<String, Object?> json) =>
      _$WithdrawalDtoFromJson(json);

  final String id;
  final String? userName;
  final int amount;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final WithdrawalReceiptDto? receipt;

  Map<String, Object?> toJson() => _$WithdrawalDtoToJson(this);
}
