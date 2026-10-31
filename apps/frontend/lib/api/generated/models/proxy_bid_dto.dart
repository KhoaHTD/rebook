// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'proxy_bid_dto.g.dart';

@JsonSerializable()
class ProxyBidDto {
  const ProxyBidDto({
    required this.lotId,
    required this.maxAmount,
    required this.active,
  });

  factory ProxyBidDto.fromJson(Map<String, Object?> json) =>
      _$ProxyBidDtoFromJson(json);

  final String lotId;
  final int maxAmount;
  final bool active;

  Map<String, Object?> toJson() => _$ProxyBidDtoToJson(this);
}
