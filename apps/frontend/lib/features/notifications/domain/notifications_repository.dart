import 'package:book_marketplace/shared/domain/commerce.dart';

/// Thông báo trong app (SRS mục 3). Thông báo đẩy đi qua core/notifications.
abstract interface class NotificationsRepository {
  Future<List<AppNotification>> list();

  /// [id] null = đánh dấu tất cả.
  Future<void> markRead(String? id);
}
