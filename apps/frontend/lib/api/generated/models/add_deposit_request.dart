// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'add_deposit_request.g.dart';

@JsonSerializable()
class AddDepositRequest {
  const AddDepositRequest({required this.amount});

  factory AddDepositRequest.fromJson(Map<String, Object?> json) =>
      _$AddDepositRequestFromJson(json);

  final num amount;

  Map<String, Object?> toJson() => _$AddDepositRequestToJson(this);
}
