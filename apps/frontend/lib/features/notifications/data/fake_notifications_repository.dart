import 'package:book_marketplace/features/notifications/domain/notifications_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<AppNotification>> list() =>
      fakeCall(_store.myNotifications, ms: 120);

  @override
  Future<void> markRead(String? id) =>
      fakeCall(() => _store.markRead(id), ms: 60);
}
