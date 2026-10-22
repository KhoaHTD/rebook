// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_dto.dart';

part 'user_page.g.dart';

@JsonSerializable()
class UserPage {
  const UserPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  factory UserPage.fromJson(Map<String, Object?> json) =>
      _$UserPageFromJson(json);

  final List<UserDto> items;
  final int page;
  final int size;
  final int total;

  Map<String, Object?> toJson() => _$UserPageToJson(this);
}
