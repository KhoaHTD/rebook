import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/auction/data/auction_repository_provider.dart';
import 'package:book_marketplace/features/auction/data/fake_auction_repository.dart';
import 'package:book_marketplace/features/auction/domain/auction_repository.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

/// Đếm số lần danh sách phiên được tải, còn lại dùng bản giả.
class _Counting extends FakeAuctionRepository {
  _Counting(super.store);

  int sessionCalls = 0;

  @override
  Future<List<AuctionSession>> sessions({SessionStatus? status}) {
    sessionCalls++;
    return super.sessions(status: status);
  }
}

void main() {
  test(
    'danh sách phiên tự tải lại sau 15 giây để thấy phiên vừa được mở',
    () async {
      final store = FakeStore()..login('minhanh@rebook.vn', '123456');
      addTearDown(store.dispose);
      final repo = _Counting(store);
      final container = ProviderContainer(
        overrides: [
          auctionRepositoryProvider.overrideWithValue(
            repo as AuctionRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(auctionSessionsProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(auctionSessionsProvider.future);
      expect(repo.sessionCalls, 1);

      await Future<void>.delayed(const Duration(seconds: 16));
      await container.read(auctionSessionsProvider.future);
      expect(repo.sessionCalls, 2);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
