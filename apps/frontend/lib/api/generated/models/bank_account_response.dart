// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bank_account_response.g.dart';

@JsonSerializable()
class BankAccountResponse {
  const BankAccountResponse({
    this.id,
    this.bankName,
    this.accountNumber,
    this.accountHolder,
    this.favorite,
    this.lastUsedAt,
  });
  
  factory BankAccountResponse.fromJson(Map<String, Object?> json) => _$BankAccountResponseFromJson(json);
  
  final int? id;
  final String? bankName;
  final String? accountNumber;
  final String? accountHolder;
  final bool? favorite;
  final DateTime? lastUsedAt;

  Map<String, Object?> toJson() => _$BankAccountResponseToJson(this);
}
