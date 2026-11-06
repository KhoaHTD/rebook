// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'bid_request.g.dart';

@JsonSerializable()
class BidRequest {
  const BidRequest({required this.amount});

  factory BidRequest.fromJson(Map<String, Object?> json) =>
      _$BidRequestFromJson(json);

  final num amount;

  Map<String, Object?> toJson() => _$BidRequestToJson(this);
}
