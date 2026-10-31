// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'wallet_dto.g.dart';

@JsonSerializable()
class WalletDto {
  const WalletDto({required this.availableBalance, required this.heldBalance});

  factory WalletDto.fromJson(Map<String, Object?> json) =>
      _$WalletDtoFromJson(json);

  final int availableBalance;
  final int heldBalance;

  Map<String, Object?> toJson() => _$WalletDtoToJson(this);
}
