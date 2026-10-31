import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/auction/data/auction_repository_provider.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

part 'second_chance_providers.g.dart';

/// Lời mời mua lần hai của tôi (SRS 6.6).
@riverpod
Future<List<SecondChanceOffer>> secondChanceOffers(Ref ref) {
  ref.watchArea(DataArea.auctions);
  if (ref.watch(currentUserProvider) == null) return Future.value(const []);
  return ref.watch(auctionRepositoryProvider).secondChanceOffers();
}

/// Số lời mời còn hiệu lực (chấm đỏ ở hồ sơ đấu giá).
@riverpod
int pendingOfferCount(Ref ref) =>
    ref
        .watch(secondChanceOffersProvider)
        .value
        ?.where(
          (o) =>
              o.status == SecondChanceStatus.pending &&
              o.expiresAt.isAfter(DateTime.now()),
        )
        .length ??
    0;

@riverpod
class SecondChanceActions extends _$SecondChanceActions {
  @override
  FutureOr<void> build() {}

  /// Nhận mua → hoá đơn lô; null nếu lỗi (xem `state.error`).
  Future<Order?> accept(String id) async {
    state = const AsyncLoading();
    Order? order;
    state = await AsyncValue.guard(() async {
      order = await ref.read(auctionRepositoryProvider).acceptSecondChance(id);
    });
    if (!state.hasError) {
      ref.read(dataChangesProvider.notifier)
        ..bump(DataArea.auctions)
        ..bump(DataArea.orders)
        ..bump(DataArea.notifications);
    }
    return order;
  }

  Future<bool> decline(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(auctionRepositoryProvider).declineSecondChance(id),
    );
    if (!state.hasError) {
      ref.read(dataChangesProvider.notifier).bump(DataArea.auctions);
    }
    return !state.hasError;
  }
}
