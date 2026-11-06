// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'cod_remit_request.g.dart';

@JsonSerializable()
class CodRemitRequest {
  const CodRemitRequest({required this.amount, this.reference});

  factory CodRemitRequest.fromJson(Map<String, Object?> json) =>
      _$CodRemitRequestFromJson(json);

  final num amount;
  final String? reference;

  Map<String, Object?> toJson() => _$CodRemitRequestToJson(this);
}
