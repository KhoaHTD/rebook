import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/features/admin/data/fake_admin_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

void main() {
  late FakeStore store;
  tearDown(() => store.dispose());

  test('admin: duyệt tin, khóa người dùng, cấu hình phí', () async {
    store = FakeStore()..login('admin@rebook.vn', '123456');
    final repo = FakeAdminRepository(store);
    final pending = await repo.listings(status: ListingStatus.pendingReview);
    if (pending.isNotEmpty) {
      final l = await repo.reviewListing(pending.first.id, approve: true);
      expect(l.status, ListingStatus.active);
    }
    final users = await repo.users(q: 'khoa');
    final locked = await repo.setLocked(users.single.id, locked: true);
    expect(locked.locked, isTrue);

    final config = await repo.config();
    final updated = await repo.updateConfig(
      config.copyWith(buyerPremiumPercent: 12),
    );
    expect(updated.buyerPremiumPercent, 12);
  });

  test('admin: tạo phiên nháp, xếp lô sẵn sàng, công bố', () async {
    store = FakeStore()..login('admin@rebook.vn', '123456');
    final repo = FakeAdminRepository(store);
    final draft = (await repo.sessions()).firstWhere(
      (s) => s.status == SessionStatus.draft,
    );
    final ready = await repo.lots(status: LotStatus.ready);
    final (s, lots) = await repo.setLots(draft.id, [
      for (final l in ready.take(2)) l.id,
    ]);
    expect(lots.length, ready.take(2).length);
    final published = await repo.publish(s.id);
    expect(published.status, SessionStatus.published);
  });
}
