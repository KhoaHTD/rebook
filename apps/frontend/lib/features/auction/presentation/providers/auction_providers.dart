import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/features/auction/data/auction_repository_provider.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';

part 'auction_providers.g.dart';

@riverpod
Future<List<Auction>> auctionList(Ref ref) =>
    ref.watch(auctionRepositoryProvider).listAuctions();

/// Lô đang diễn ra đầu tiên (cho thanh "đang đấu giá" phía trên thanh tab), null nếu không có.
@riverpod
Future<Auction?> liveAuction(Ref ref) async {
  final all = await ref.watch(auctionListProvider.future);
  final now = DateTime.now();
  for (final a in all) {
    if (a.isLiveAt(now)) return a;
  }
  return null;
}

/// Trạng thái live của một phiên. Tự huỷ kết nối khi rời màn hình (autoDispose).
@riverpod
Stream<Auction> auctionRoom(Ref ref, String auctionId) =>
    ref.watch(auctionRepositoryProvider).watchAuction(auctionId);

@riverpod
Future<LotDetail> lotDetail(Ref ref, String lotId) =>
    ref.watch(auctionRepositoryProvider).getLot(lotId);

/// Hành động trả giá. `state` là AsyncValue của lần trả giá gần nhất
/// (loading -> nút bị disable, error -> hiện snackbar).
@riverpod
class BidController extends _$BidController {
  @override
  FutureOr<void> build(String auctionId) {}

  /// Trả về `true` nếu thành công.
  Future<bool> placeBid(int amount) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(auctionRepositoryProvider).placeBid(auctionId, amount),
    );
    return !state.hasError;
  }

  /// Bật / tắt giá tối đa tự trả. Trả về `true` nếu thành công.
  Future<bool> setProxy(int? maxAmount) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(auctionRepositoryProvider).setProxy(auctionId, maxAmount),
    );
    return !state.hasError;
  }
}

/// Đăng ký tham gia phiên + đặt cọc.
@riverpod
class LotRegistration extends _$LotRegistration {
  @override
  FutureOr<void> build(String lotId) {}

  Future<bool> register() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(auctionRepositoryProvider).register(lotId);
      ref.invalidate(lotDetailProvider(lotId));
    });
    return !state.hasError;
  }
}

/// Theo dõi lô. `state` = đang theo dõi hay không.
@riverpod
class LotFollow extends _$LotFollow {
  @override
  Future<bool> build(String lotId) async =>
      (await ref.watch(lotDetailProvider(lotId).future)).following;

  Future<void> toggle() async {
    final current = state.value ?? false;
    state = await AsyncValue.guard(
      () => ref
          .read(auctionRepositoryProvider)
          .setFollowing(lotId, following: !current),
    );
  }
}
