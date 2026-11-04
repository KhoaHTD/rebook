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
    final res = await _client.notification.getNotifications(size: 50);
    return [for (final n in res.items.orEmpty) n.toDomain()];
  });

  /// `id == null` = đánh dấu đã đọc tất cả.
  @override
  Future<void> markRead(String? id) => guardApi(
    () => id == null
        ? _client.notification.postNotificationsReadAll()
        : _client.notification.postNotificationsIdRead(id: apiId(id)),
  );
}
