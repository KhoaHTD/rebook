// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'dashboard_dto.g.dart';

@JsonSerializable()
class DashboardDto {
  const DashboardDto({
    required this.revenueTotal,
    required this.platformFees,
    required this.orderCount,
    required this.lotSoldRate,
    required this.activeUsers,
    required this.pendingListings,
    required this.pendingConsignments,
  });

  factory DashboardDto.fromJson(Map<String, Object?> json) =>
      _$DashboardDtoFromJson(json);

  final int revenueTotal;
  final int platformFees;
  final int orderCount;
  final double lotSoldRate;
  final int activeUsers;
  final int pendingListings;
  final int pendingConsignments;

  Map<String, Object?> toJson() => _$DashboardDtoToJson(this);
}
