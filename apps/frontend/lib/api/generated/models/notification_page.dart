// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_dto.dart';

part 'notification_page.g.dart';

@JsonSerializable()
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  factory NotificationPage.fromJson(Map<String, Object?> json) =>
      _$NotificationPageFromJson(json);

  final List<NotificationDto> items;
  final int page;
  final int size;
  final int total;

  Map<String, Object?> toJson() => _$NotificationPageToJson(this);
}
