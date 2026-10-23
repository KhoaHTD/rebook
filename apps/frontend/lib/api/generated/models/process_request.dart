// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'process_request.g.dart';

@JsonSerializable()
class ProcessRequest {
  const ProcessRequest({this.approve, this.note});

  factory ProcessRequest.fromJson(Map<String, Object?> json) =>
      _$ProcessRequestFromJson(json);

  final bool? approve;
  final String? note;

  Map<String, Object?> toJson() => _$ProcessRequestToJson(this);
}
