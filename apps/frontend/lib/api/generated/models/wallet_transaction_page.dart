// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'wallet_transaction_dto.dart';

part 'wallet_transaction_page.g.dart';

@JsonSerializable()
class WalletTransactionPage {
  const WalletTransactionPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  factory WalletTransactionPage.fromJson(Map<String, Object?> json) =>
      _$WalletTransactionPageFromJson(json);

  final List<WalletTransactionDto> items;
  final int page;
  final int size;
  final int total;

  Map<String, Object?> toJson() => _$WalletTransactionPageToJson(this);
}
