// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'wallet_tx_type.dart';

part 'transaction_response.g.dart';

@JsonSerializable()
class TransactionResponse {
  const TransactionResponse({
    this.id,
    this.type,
    this.availableChange,
    this.heldChange,
    this.availableAfter,
    this.heldAfter,
    this.refType,
    this.refId,
    this.note,
    this.createdAt,
  });

  factory TransactionResponse.fromJson(Map<String, Object?> json) =>
      _$TransactionResponseFromJson(json);

  final int? id;
  final WalletTxType? type;
  final num? availableChange;
  final num? heldChange;
  final num? availableAfter;
  final num? heldAfter;
  final String? refType;
  final int? refId;
  final String? note;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$TransactionResponseToJson(this);
}
