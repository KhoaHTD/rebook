// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/page_response_notification_response.dart';

part 'notification_client.g.dart';

@RestApi()
abstract class NotificationClient {
  factory NotificationClient(Dio dio, {String? baseUrl}) = _NotificationClient;

  @POST('/notifications/{id}/read')
  Future<void> postNotificationsIdRead({@Path('id') required int id});

  @POST('/notifications/read-all')
  Future<void> postNotificationsReadAll();

  @GET('/notifications')
  Future<PageResponseNotificationResponse> getNotifications({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });

  @GET('/notifications/unread-count')
  Future<Map<String, int>> getNotificationsUnreadCount();
}
