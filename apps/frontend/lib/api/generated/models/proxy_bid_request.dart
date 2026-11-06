// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'proxy_bid_request.g.dart';

@JsonSerializable()
class ProxyBidRequest {
  const ProxyBidRequest({required this.maxAmount});

  factory ProxyBidRequest.fromJson(Map<String, Object?> json) =>
      _$ProxyBidRequestFromJson(json);

  final num maxAmount;

  Map<String, Object?> toJson() => _$ProxyBidRequestToJson(this);
}
