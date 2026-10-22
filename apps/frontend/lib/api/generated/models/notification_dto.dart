// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'notification_type.dart';

part 'notification_dto.g.dart';

@JsonSerializable()
class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.link,
  });

  factory NotificationDto.fromJson(Map<String, Object?> json) =>
      _$NotificationDtoFromJson(json);

  final String id;
  final NotificationType type;
  final String title;
  final String body;

  /// Đường dẫn trong app, vd /orders/123, /auctions/sessions/9
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  Map<String, Object?> toJson() => _$NotificationDtoToJson(this);
}
