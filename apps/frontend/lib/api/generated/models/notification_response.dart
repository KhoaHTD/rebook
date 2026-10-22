// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'notification_response.g.dart';

@JsonSerializable()
class NotificationResponse {
  const NotificationResponse({
    this.id,
    this.type,
    this.title,
    this.body,
    this.data,
    this.read,
    this.createdAt,
  });

  factory NotificationResponse.fromJson(Map<String, Object?> json) =>
      _$NotificationResponseFromJson(json);

  final int? id;
  final String? type;
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool? read;
  final DateTime? createdAt;

  Map<String, Object?> toJson() => _$NotificationResponseToJson(this);
}
