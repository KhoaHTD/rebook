import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/features/auction/data/auction_repository_provider.dart';
import 'package:book_marketplace/features/auction/domain/auction.dart';

part 'auction_providers.g.dart';

@riverpod
Future<List<Auction>> auctionList(Ref ref) =>
    ref.watch(auctionRepositoryProvider).listAuctions();

/// Trạng thái live của một phiên. Tự huỷ kết nối khi rời màn hình (autoDispose).
@riverpod
Stream<Auction> auctionRoom(Ref ref, String auctionId) =>
    ref.watch(auctionRepositoryProvider).watchAuction(auctionId);

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
}
