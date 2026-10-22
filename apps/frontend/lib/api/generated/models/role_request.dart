// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'role.dart';

part 'role_request.g.dart';

@JsonSerializable()
class RoleRequest {
  const RoleRequest({required this.role});

  factory RoleRequest.fromJson(Map<String, Object?> json) =>
      _$RoleRequestFromJson(json);

  final Role role;

  Map<String, Object?> toJson() => _$RoleRequestToJson(this);
}
