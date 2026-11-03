// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'file_response.g.dart';

@JsonSerializable()
class FileResponse {
  const FileResponse({this.url, this.contentType, this.size});

  factory FileResponse.fromJson(Map<String, Object?> json) =>
      _$FileResponseFromJson(json);

  final String? url;
  final String? contentType;
  final int? size;

  Map<String, Object?> toJson() => _$FileResponseToJson(this);
}
