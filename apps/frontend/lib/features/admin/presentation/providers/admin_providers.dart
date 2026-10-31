import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/admin/data/admin_repository_provider.dart';
import 'package:book_marketplace/features/admin/domain/admin_repository.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'admin_providers.g.dart';

@riverpod
Future<Dashboard> dashboard(Ref ref) {
  ref
    ..watchArea(DataArea.orders)
    ..watchArea(DataArea.listings)
    ..watchArea(DataArea.consignments);
  return ref.watch(adminRepositoryProvider).dashboard();
}

@riverpod
Future<List<Listing>> pendingListings(Ref ref) {
  ref.watchArea(DataArea.listings);
  return ref
      .watch(adminRepositoryProvider)
      .listings(status: ListingStatus.pendingReview);
}

@riverpod
class UserQuery extends _$UserQuery {
  @override
  String build() => '';

  void set(String q) => state = q;
}

@riverpod
Future<List<AppUser>> adminUsers(Ref ref) {
  ref.watchArea(DataArea.profile);
  return ref
      .watch(adminRepositoryProvider)
      .users(q: ref.watch(userQueryProvider));
}

@riverpod
Future<List<Category>> adminCategories(Ref ref) {
  ref.watchArea(DataArea.listings);
  return ref.watch(adminRepositoryProvider).categories();
}

@riverpod
Future<List<AuctionSession>> adminSessions(Ref ref) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(adminRepositoryProvider).sessions();
}

@riverpod
Future<(AuctionSession, List<Lot>)> adminSession(Ref ref, String id) {
  ref.watchArea(DataArea.auctions);
  return ref.watch(adminRepositoryProvider).session(id);
}

/// Lô sẵn sàng (chưa xếp phiên) để xếp vào phiên.
@riverpod
Future<List<Lot>> readyLots(Ref ref) {
  ref
    ..watchArea(DataArea.auctions)
    ..watchArea(DataArea.consignments);
  return ref.watch(adminRepositoryProvider).lots(status: LotStatus.ready);
}

/// Màn giám sát: hỏi lại trạng thái phiên mỗi 2 giây.
@riverpod
Future<SessionState> monitorState(Ref ref, String id) {
  final timer = Timer(const Duration(seconds: 2), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(adminRepositoryProvider).sessionState(id);
}

@riverpod
Future<SystemConfig> systemConfig(Ref ref) =>
    ref.watch(adminRepositoryProvider).config();

@riverpod
Future<List<Withdrawal>> adminWithdrawals(Ref ref) {
  ref.watchArea(DataArea.wallet);
  return ref.watch(adminRepositoryProvider).withdrawals();
}

/// Nhật ký hoạt động của Admin (SRS 8.1). Tải lại mỗi khi có vùng dữ liệu liên quan đổi.
@riverpod
Future<List<ActivityLog>> adminActivityLogs(Ref ref) {
  ref.watchArea(DataArea.wallet);
  ref.watchArea(DataArea.listings);
  ref.watchArea(DataArea.profile);
  ref.watchArea(DataArea.warehouse);
  return ref.watch(adminRepositoryProvider).activityLogs();
}

@riverpod
Future<List<Order>> adminDisputes(Ref ref) {
  ref.watchArea(DataArea.orders);
  return ref.watch(adminRepositoryProvider).disputes();
}

/// Mọi thao tác ghi của quản trị.
@riverpod
class AdminActions extends _$AdminActions {
  @override
  FutureOr<void> build() {}

  Future<T?> run<T>(
    Future<T> Function(AdminRepository repo) action,
    List<String> areas,
  ) async {
    state = const AsyncLoading();
    T? result;
    state = await AsyncValue.guard(() async {
      result = await action(ref.read(adminRepositoryProvider));
    });
    if (!state.hasError) {
      final changes = ref.read(dataChangesProvider.notifier);
      for (final a in areas) {
        changes.bump(a);
      }
    }
    return result;
  }
}
