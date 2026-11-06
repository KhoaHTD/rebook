// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'chargeback_request.g.dart';

@JsonSerializable()
class ChargebackRequest {
  const ChargebackRequest({
    required this.userId,
    required this.amount,
    required this.reason,
  });

  factory ChargebackRequest.fromJson(Map<String, Object?> json) =>
      _$ChargebackRequestFromJson(json);

  final int userId;
  final num amount;
  final String reason;

  Map<String, Object?> toJson() => _$ChargebackRequestToJson(this);
}
