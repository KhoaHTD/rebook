// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'transfer_receipt.dart';
import 'withdraw_status.dart';

part 'withdraw_response.g.dart';

@JsonSerializable()
class WithdrawResponse {
  const WithdrawResponse({
    this.id,
    this.userId,
    this.userName,
    this.amount,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
    this.status,
    this.note,
    this.processedBy,
    this.processedByName,
    this.processedAt,
    this.createdAt,
    this.transfer,
    this.userNote,
  });
  
  factory WithdrawResponse.fromJson(Map<String, Object?> json) => _$WithdrawResponseFromJson(json);
  
  final int? id;
  final int? userId;
  final String? userName;
  final num? amount;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;
  final WithdrawStatus? status;
  final String? note;
  final int? processedBy;
  final String? processedByName;
  final DateTime? processedAt;
  final DateTime? createdAt;
  final TransferReceipt? transfer;
  final String? userNote;

  Map<String, Object?> toJson() => _$WithdrawResponseToJson(this);
}
