import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/notifications/domain/notifications_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';

class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository(this._client);

  final api.RestClient _client;

  @override
  Future<List<AppNotification>> list() => guardApi(() async {
    final page = await _client.notifications.listNotifications(size: 100);
    return page.items.map((e) => e.toDomain()).toList();
  });

  @override
  Future<void> markRead(String? id) => guardApi(
    () => id == null
        ? _client.notifications.markAllNotificationsRead()
        : _client.notifications.markNotificationRead(id: id),
  );
}
