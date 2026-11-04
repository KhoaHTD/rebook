// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'process_request.g.dart';

@JsonSerializable()
class ProcessRequest {
  const ProcessRequest({
    this.approve,
    this.note,
    this.senderName,
    this.transferTime,
    this.transferAmount,
    this.proofImageUrl,
  });

  factory ProcessRequest.fromJson(Map<String, Object?> json) =>
      _$ProcessRequestFromJson(json);

  final bool? approve;
  final String? note;
  final String? senderName;
  final DateTime? transferTime;
  final num? transferAmount;
  final String? proofImageUrl;

  Map<String, Object?> toJson() => _$ProcessRequestToJson(this);
}
