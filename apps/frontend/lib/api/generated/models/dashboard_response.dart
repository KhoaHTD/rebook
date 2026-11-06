// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dashboard_response.g.dart';

@JsonSerializable()
class DashboardResponse {
  const DashboardResponse({
    this.revenueThisMonth,
    this.ordersThisMonth,
    this.ordersInProgress,
    this.pendingListings,
    this.activeListings,
    this.liveSessions,
    this.upcomingSessions,
    this.lotSellThroughRate,
    this.platformBalance,
  });

  factory DashboardResponse.fromJson(Map<String, Object?> json) =>
      _$DashboardResponseFromJson(json);

  final num? revenueThisMonth;
  final int? ordersThisMonth;
  final int? ordersInProgress;
  final int? pendingListings;
  final int? activeListings;
  final int? liveSessions;
  final int? upcomingSessions;
  final double? lotSellThroughRate;
  final num? platformBalance;

  Map<String, Object?> toJson() => _$DashboardResponseToJson(this);
}
