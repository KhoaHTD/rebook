// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'withdraw_create_request.g.dart';

@JsonSerializable()
class WithdrawCreateRequest {
  const WithdrawCreateRequest({
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  factory WithdrawCreateRequest.fromJson(Map<String, Object?> json) =>
      _$WithdrawCreateRequestFromJson(json);

  final num amount;
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  Map<String, Object?> toJson() => _$WithdrawCreateRequestToJson(this);
}
