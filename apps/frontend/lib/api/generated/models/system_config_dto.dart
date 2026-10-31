// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bid_increment_tier_dto.dart';

part 'system_config_dto.g.dart';

@JsonSerializable()
class SystemConfigDto {
  const SystemConfigDto({
    required this.fixedPriceFeePercent,
    required this.buyerPremiumPercent,
    required this.sellerCommissionPercent,
    required this.storageFeePerDay,
    required this.storageFreeDays,
    required this.orderPaymentTimeoutMin,
    required this.auctionPaymentTimeoutHours,
    required this.depositLimitMultiplier,
    required this.auctionBanDays,
    required this.bidIncrementTiers,
    this.returnResponseDays,
  });

  factory SystemConfigDto.fromJson(Map<String, Object?> json) =>
      _$SystemConfigDtoFromJson(json);

  final double fixedPriceFeePercent;
  final double buyerPremiumPercent;
  final double sellerCommissionPercent;
  final int storageFeePerDay;
  final int storageFreeDays;
  final int orderPaymentTimeoutMin;
  final int auctionPaymentTimeoutHours;
  final int depositLimitMultiplier;
  final int auctionBanDays;

  /// order.return_response_days — số ngày shop được trả lời yêu cầu trả hàng (mặc định 2).
  final int? returnResponseDays;
  final List<BidIncrementTierDto> bidIncrementTiers;

  Map<String, Object?> toJson() => _$SystemConfigDtoToJson(this);
}
