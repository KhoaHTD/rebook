// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/notification_page.dart';

part 'notifications_client.g.dart';

@RestApi()
abstract class NotificationsClient {
  factory NotificationsClient(Dio dio, {String? baseUrl}) =
      _NotificationsClient;

  @GET('/notifications')
  Future<NotificationPage> listNotifications({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });

  @POST('/notifications/{id}/read')
  Future<void> markNotificationRead({@Path('id') required String id});

  @POST('/notifications/read-all')
  Future<void> markAllNotificationsRead();
}
