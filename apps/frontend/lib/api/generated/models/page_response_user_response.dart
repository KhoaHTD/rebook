// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_response.dart';

part 'page_response_user_response.g.dart';

@JsonSerializable()
class PageResponseUserResponse {
  const PageResponseUserResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseUserResponse.fromJson(Map<String, Object?> json) =>
      _$PageResponseUserResponseFromJson(json);

  final List<UserResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() => _$PageResponseUserResponseToJson(this);
}
