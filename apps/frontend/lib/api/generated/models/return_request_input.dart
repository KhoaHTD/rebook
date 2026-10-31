// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'return_request_input.g.dart';

@JsonSerializable()
class ReturnRequestInput {
  const ReturnRequestInput({required this.reason, required this.imageUrls});

  factory ReturnRequestInput.fromJson(Map<String, Object?> json) =>
      _$ReturnRequestInputFromJson(json);

  final String reason;
  final List<String> imageUrls;

  Map<String, Object?> toJson() => _$ReturnRequestInputToJson(this);
}
