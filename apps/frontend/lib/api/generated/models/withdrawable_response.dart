// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'withdrawable_response.g.dart';

@JsonSerializable()
class WithdrawableResponse {
  const WithdrawableResponse({
    this.available,
    this.locked,
    this.withdrawable,
    this.unlockAt,
  });

  factory WithdrawableResponse.fromJson(Map<String, Object?> json) =>
      _$WithdrawableResponseFromJson(json);

  final num? available;
  final num? locked;
  final num? withdrawable;
  final DateTime? unlockAt;

  Map<String, Object?> toJson() => _$WithdrawableResponseToJson(this);
}
