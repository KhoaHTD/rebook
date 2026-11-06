// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'image_source.dart';

part 'image_response.g.dart';

@JsonSerializable()
class ImageResponse {
  const ImageResponse({this.url, this.source});

  factory ImageResponse.fromJson(Map<String, Object?> json) =>
      _$ImageResponseFromJson(json);

  final String? url;
  final ImageSource? source;

  Map<String, Object?> toJson() => _$ImageResponseToJson(this);
}
