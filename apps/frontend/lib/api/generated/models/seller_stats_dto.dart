// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'seller_stats_dto.g.dart';

@JsonSerializable()
class SellerStatsDto {
  const SellerStatsDto({
    required this.revenueTotal,
    required this.revenueThisMonth,
    required this.pendingBalance,
    required this.ordersToConfirm,
    required this.ordersShipping,
    required this.ordersCompleted,
    required this.activeListings,
    required this.ratingAvg,
  });

  factory SellerStatsDto.fromJson(Map<String, Object?> json) =>
      _$SellerStatsDtoFromJson(json);

  final int revenueTotal;
  final int revenueThisMonth;

  /// Tiền bán hàng đang chờ đơn hoàn tất
  final int pendingBalance;
  final int ordersToConfirm;
  final int ordersShipping;
  final int ordersCompleted;
  final int activeListings;
  final double ratingAvg;

  Map<String, Object?> toJson() => _$SellerStatsDtoToJson(this);
}
