// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'transfer_receipt.g.dart';

@JsonSerializable()
class TransferReceipt {
  const TransferReceipt({
    this.senderName,
    this.transferTime,
    this.amount,
    this.proofImageUrl,
  });

  factory TransferReceipt.fromJson(Map<String, Object?> json) =>
      _$TransferReceiptFromJson(json);

  final String? senderName;
  final DateTime? transferTime;
  final num? amount;
  final String? proofImageUrl;

  Map<String, Object?> toJson() => _$TransferReceiptToJson(this);
}
