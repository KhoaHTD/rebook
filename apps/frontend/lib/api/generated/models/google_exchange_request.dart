// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'google_exchange_request.g.dart';

@JsonSerializable()
class GoogleExchangeRequest {
  const GoogleExchangeRequest({required this.ticket});

  factory GoogleExchangeRequest.fromJson(Map<String, Object?> json) =>
      _$GoogleExchangeRequestFromJson(json);

  final String ticket;

  Map<String, Object?> toJson() => _$GoogleExchangeRequestToJson(this);
}
