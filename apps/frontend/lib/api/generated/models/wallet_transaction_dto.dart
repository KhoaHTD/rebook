// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'wallet_transaction_type.dart';

part 'wallet_transaction_dto.g.dart';

@JsonSerializable()
class WalletTransactionDto {
  const WalletTransactionDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
    this.refType,
    this.refId,
    this.note,
  });

  factory WalletTransactionDto.fromJson(Map<String, Object?> json) =>
      _$WalletTransactionDtoFromJson(json);

  final String id;
  final WalletTransactionType type;

  /// Âm = tiền ra
  final int amount;
  final int balanceAfter;
  final String? refType;
  final String? refId;
  final String? note;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$WalletTransactionDtoToJson(this);
}
