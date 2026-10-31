// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_role.dart';
import 'user_status.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.phoneVerified,
    required this.hasShop,
    this.phone,
    this.avatarUrl,
    this.auctionBannedUntil,
    this.createdAt,
  });

  factory UserDto.fromJson(Map<String, Object?> json) =>
      _$UserDtoFromJson(json);

  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String? avatarUrl;
  final UserRole role;
  final UserStatus status;
  final bool phoneVerified;
  final bool hasShop;
  final DateTime? auctionBannedUntil;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$UserDtoToJson(this);
}
