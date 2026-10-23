// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bid_view.g.dart';

@JsonSerializable()
class BidView {
  const BidView({this.paddle, this.amount, this.auto, this.at});

  factory BidView.fromJson(Map<String, Object?> json) =>
      _$BidViewFromJson(json);

  final String? paddle;
  final num? amount;
  final bool? auto;
  final DateTime? at;

  Map<String, Object?> toJson() => _$BidViewToJson(this);
}
