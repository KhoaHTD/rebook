// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'bid_view.dart';
import 'lot_close_result.dart';
import 'lot_status.dart';

part 'lot_live.g.dart';

@JsonSerializable()
class LotLive {
  const LotLive({
    this.id,
    this.lotNumber,
    this.title,
    this.coverUrl,
    this.status,
    this.startPrice,
    this.currentPrice,
    this.nextMinBid,
    this.increment,
    this.bidCount,
    this.endsAt,
    this.leadingPaddle,
    this.recentBids,
    this.closeResult,
    this.hammerPrice,
  });

  factory LotLive.fromJson(Map<String, Object?> json) =>
      _$LotLiveFromJson(json);

  final int? id;
  final int? lotNumber;
  final String? title;
  final String? coverUrl;
  final LotStatus? status;
  final num? startPrice;
  final num? currentPrice;
  final num? nextMinBid;
  final num? increment;
  final int? bidCount;
  final DateTime? endsAt;
  final String? leadingPaddle;
  final List<BidView>? recentBids;
  final LotCloseResult? closeResult;
  final num? hammerPrice;

  Map<String, Object?> toJson() => _$LotLiveToJson(this);
}
