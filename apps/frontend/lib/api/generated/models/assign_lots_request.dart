// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'assign_lots_request.g.dart';

@JsonSerializable()
class AssignLotsRequest {
  const AssignLotsRequest({required this.lotIds});

  factory AssignLotsRequest.fromJson(Map<String, Object?> json) =>
      _$AssignLotsRequestFromJson(json);

  final List<int> lotIds;

  Map<String, Object?> toJson() => _$AssignLotsRequestToJson(this);
}
