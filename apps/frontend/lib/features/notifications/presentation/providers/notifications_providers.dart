import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/notifications/data/notifications_repository_provider.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';

part 'notifications_providers.g.dart';

/// Danh sách thông báo. Backend thật không đẩy qua kênh này nên hỏi lại mỗi 60 giây.
@riverpod
Future<List<AppNotification>> notifications(Ref ref) async {
  ref.watchArea(DataArea.notifications);
  if (ref.watch(currentUserProvider) == null) return const [];
  if (!Env.useMock) {
    final timer = Timer(const Duration(seconds: 60), ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return ref.watch(notificationsRepositoryProvider).list();
}

/// Số thông báo chưa đọc (chấm đỏ trên tab Thông báo).
@riverpod
int unreadCount(Ref ref) =>
    ref.watch(notificationsProvider).value?.where((n) => !n.isRead).length ?? 0;

@riverpod
class NotificationActions extends _$NotificationActions {
  @override
  FutureOr<void> build() {}

  Future<void> markRead(String? id) async {
    await ref.read(notificationsRepositoryProvider).markRead(id);
    ref.read(dataChangesProvider.notifier).bump(DataArea.notifications);
  }
}
