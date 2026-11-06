// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'lot_live.dart';
import 'registration_response.dart';

part 'bid_response.g.dart';

@JsonSerializable()
class BidResponse {
  const BidResponse({this.lot, this.leading, this.me});

  factory BidResponse.fromJson(Map<String, Object?> json) =>
      _$BidResponseFromJson(json);

  final LotLive? lot;
  final bool? leading;
  final RegistrationResponse? me;

  Map<String, Object?> toJson() => _$BidResponseToJson(this);
}
