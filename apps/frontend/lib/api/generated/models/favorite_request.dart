// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'favorite_request.g.dart';

@JsonSerializable()
class FavoriteRequest {
  const FavoriteRequest({required this.favorite});

  factory FavoriteRequest.fromJson(Map<String, Object?> json) =>
      _$FavoriteRequestFromJson(json);

  final bool favorite;

  Map<String, Object?> toJson() => _$FavoriteRequestToJson(this);
}
