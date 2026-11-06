// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'wallet_response.g.dart';

@JsonSerializable()
class WalletResponse {
  const WalletResponse({this.availableBalance, this.heldBalance});

  factory WalletResponse.fromJson(Map<String, Object?> json) =>
      _$WalletResponseFromJson(json);

  final num? availableBalance;
  final num? heldBalance;

  Map<String, Object?> toJson() => _$WalletResponseToJson(this);
}
