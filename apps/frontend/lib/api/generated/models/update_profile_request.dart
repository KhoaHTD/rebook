// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request.g.dart';

@JsonSerializable()
class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.fullName,
    this.phone,
    this.avatarUrl,
  });

  factory UpdateProfileRequest.fromJson(Map<String, Object?> json) =>
      _$UpdateProfileRequestFromJson(json);

  final String fullName;
  final String? phone;
  final String? avatarUrl;

  Map<String, Object?> toJson() => _$UpdateProfileRequestToJson(this);
}
