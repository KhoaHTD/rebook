// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bank_account_dto.g.dart';

@JsonSerializable()
class BankAccountDto {
  const BankAccountDto({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.favorite,
    required this.lastUsedAt,
  });

  factory BankAccountDto.fromJson(Map<String, Object?> json) =>
      _$BankAccountDtoFromJson(json);

  final String id;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final bool favorite;
  final DateTime lastUsedAt;

  Map<String, Object?> toJson() => _$BankAccountDtoToJson(this);
}
