// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'watch_request.g.dart';

@JsonSerializable()
class WatchRequest {
  const WatchRequest({required this.watch});

  factory WatchRequest.fromJson(Map<String, Object?> json) =>
      _$WatchRequestFromJson(json);

  final bool watch;

  Map<String, Object?> toJson() => _$WatchRequestToJson(this);
}
