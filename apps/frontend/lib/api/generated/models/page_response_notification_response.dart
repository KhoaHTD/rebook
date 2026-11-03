// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_response.dart';

part 'page_response_notification_response.g.dart';

@JsonSerializable()
class PageResponseNotificationResponse {
  const PageResponseNotificationResponse({
    this.items,
    this.page,
    this.size,
    this.totalItems,
    this.totalPages,
  });

  factory PageResponseNotificationResponse.fromJson(
    Map<String, Object?> json,
  ) => _$PageResponseNotificationResponseFromJson(json);

  final List<NotificationResponse>? items;
  final int? page;
  final int? size;
  final int? totalItems;
  final int? totalPages;

  Map<String, Object?> toJson() =>
      _$PageResponseNotificationResponseToJson(this);
}
