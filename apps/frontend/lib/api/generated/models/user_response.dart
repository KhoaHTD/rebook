// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'role.dart';
import 'user_status.dart';

part 'user_response.g.dart';

@JsonSerializable()
class UserResponse {
  const UserResponse({
    this.id,
    this.email,
    this.phone,
    this.fullName,
    this.avatarUrl,
    this.role,
    this.status,
    this.emailVerified,
    this.phoneVerified,
    this.auctionBannedUntil,
    this.shopId,
    this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, Object?> json) =>
      _$UserResponseFromJson(json);

  final int? id;
  final String? email;
  final String? phone;
  final String? fullName;
  final String? avatarUrl;
  final Role? role;
  final UserStatus? status;
  final bool? emailVerified;
  final bool? phoneVerified;
  final DateTime? auctionBannedUntil;
  final int? shopId;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$UserResponseToJson(this);
}
