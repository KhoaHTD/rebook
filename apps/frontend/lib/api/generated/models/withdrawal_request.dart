// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'withdrawal_request.g.dart';

@JsonSerializable()
class WithdrawalRequest {
  const WithdrawalRequest({
    required this.amount,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountName,
    this.note,
  });

  factory WithdrawalRequest.fromJson(Map<String, Object?> json) =>
      _$WithdrawalRequestFromJson(json);

  final int amount;
  final String bankName;
  final String bankAccountNumber;

  /// IN HOA
  final String bankAccountName;
  final String? note;

  Map<String, Object?> toJson() => _$WithdrawalRequestToJson(this);
}
