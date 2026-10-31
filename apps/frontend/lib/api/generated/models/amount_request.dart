// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'amount_request.g.dart';

@JsonSerializable()
class AmountRequest {
  const AmountRequest({required this.amount});

  factory AmountRequest.fromJson(Map<String, Object?> json) =>
      _$AmountRequestFromJson(json);

  final int amount;

  Map<String, Object?> toJson() => _$AmountRequestToJson(this);
}
