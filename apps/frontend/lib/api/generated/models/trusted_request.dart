// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'trusted_request.g.dart';

@JsonSerializable()
class TrustedRequest {
  const TrustedRequest({this.trusted});

  factory TrustedRequest.fromJson(Map<String, Object?> json) =>
      _$TrustedRequestFromJson(json);

  final bool? trusted;

  Map<String, Object?> toJson() => _$TrustedRequestToJson(this);
}
