// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'session_lots_request.g.dart';

@JsonSerializable()
class SessionLotsRequest {
  const SessionLotsRequest({required this.lotIds});

  factory SessionLotsRequest.fromJson(Map<String, Object?> json) =>
      _$SessionLotsRequestFromJson(json);

  final List<String> lotIds;

  Map<String, Object?> toJson() => _$SessionLotsRequestToJson(this);
}
