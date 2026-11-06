// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_slice.dart';
import 'day.dart';
import 'status_slice.dart';

part 'report_response.g.dart';

@JsonSerializable()
class ReportResponse {
  const ReportResponse({
    this.from,
    this.to,
    this.gmv,
    this.revenue,
    this.platformFees,
    this.orders,
    this.completedOrders,
    this.cancelledOrders,
    this.auctionOrders,
    this.newUsers,
    this.days,
    this.categories,
    this.statuses,
  });

  factory ReportResponse.fromJson(Map<String, Object?> json) =>
      _$ReportResponseFromJson(json);

  final DateTime? from;
  final DateTime? to;
  final num? gmv;
  final num? revenue;
  final num? platformFees;
  final int? orders;
  final int? completedOrders;
  final int? cancelledOrders;
  final int? auctionOrders;
  final int? newUsers;
  final List<Day>? days;
  final List<CategorySlice>? categories;
  final List<StatusSlice>? statuses;

  Map<String, Object?> toJson() => _$ReportResponseToJson(this);
}
