import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/notifications/data/api_notifications_repository.dart';
import 'package:book_marketplace/features/notifications/data/fake_notifications_repository.dart';
import 'package:book_marketplace/features/notifications/domain/notifications_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'notifications_repository_provider.g.dart';

@riverpod
NotificationsRepository notificationsRepository(Ref ref) => Env.useMock
    ? FakeNotificationsRepository(ref.watch(fakeStoreProvider))
    : ApiNotificationsRepository(ref.watch(restClientProvider));
