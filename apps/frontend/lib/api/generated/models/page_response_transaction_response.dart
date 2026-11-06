// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'transaction_response.dart';

part 'page_response_transaction_response.g.dart';

@JsonSerializable()
class PageResponseTransactionResponse {
  const PageResponseTransactionResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseTransactionResponse.fromJson(Map<String, Object?> json) =>
      _$PageResponseTransactionResponseFromJson(json);

  final List<TransactionResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() =>
      _$PageResponseTransactionResponseToJson(this);
}
