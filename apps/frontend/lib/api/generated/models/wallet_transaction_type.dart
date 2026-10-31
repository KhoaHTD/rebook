// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum WalletTransactionType {
  @JsonValue('TOP_UP')
  topUp('TOP_UP'),
  @JsonValue('PAYMENT')
  payment('PAYMENT'),
  @JsonValue('REFUND')
  refund('REFUND'),
  @JsonValue('DEPOSIT_HOLD')
  depositHold('DEPOSIT_HOLD'),
  @JsonValue('DEPOSIT_RELEASE')
  depositRelease('DEPOSIT_RELEASE'),
  @JsonValue('DEPOSIT_FORFEIT')
  depositForfeit('DEPOSIT_FORFEIT'),
  @JsonValue('SALE_PENDING')
  salePending('SALE_PENDING'),
  @JsonValue('SALE_RELEASE')
  saleRelease('SALE_RELEASE'),
  @JsonValue('FEE')
  fee('FEE'),
  @JsonValue('WITHDRAW')
  withdraw('WITHDRAW'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const WalletTransactionType(this.json);

  factory WalletTransactionType.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<WalletTransactionType> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
