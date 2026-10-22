// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'upload_signature_dto.g.dart';

@JsonSerializable()
class UploadSignatureDto {
  const UploadSignatureDto({
    required this.cloudName,
    required this.apiKey,
    required this.timestamp,
    required this.signature,
    required this.folder,
  });

  factory UploadSignatureDto.fromJson(Map<String, Object?> json) =>
      _$UploadSignatureDtoFromJson(json);

  final String cloudName;
  final String apiKey;
  final int timestamp;
  final String signature;
  final String folder;

  Map<String, Object?> toJson() => _$UploadSignatureDtoToJson(this);
}
