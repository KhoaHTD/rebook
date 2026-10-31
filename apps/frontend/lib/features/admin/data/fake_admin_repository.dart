import 'package:book_marketplace/features/admin/domain/admin_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository(this._store);

  final FakeStore _store;

  @override
  Future<Dashboard> dashboard() => fakeCall(_store.dashboard);

  @override
  Future<List<Listing>> listings({ListingStatus? status}) =>
      fakeCall(() => _store.listingsByStatus(status));

  @override
  Future<Listing> reviewListing(
    String id, {
    required bool approve,
    String? reason,
  }) => fakeCall(
    () => _store.reviewListing(id, approve: approve, reason: reason),
  );

  @override
  Future<List<AppUser>> users({String? q}) => fakeCall(() {
    final text = q?.trim().toLowerCase() ?? '';
    return _store
        .allUsers()
        .where(
          (u) =>
              text.isEmpty ||
              u.fullName.toLowerCase().contains(text) ||
              u.email.contains(text),
        )
        .toList();
  });

  @override
  Future<AppUser> setLocked(
    String id, {
    required bool locked,
    String? reason,
  }) => fakeCall(() => _store.setLocked(id, locked: locked));

  @override
  Future<List<Category>> categories() =>
      fakeCall(() => List.of(_store.categories));

  @override
  Future<Category> saveCategory(String? id, String name, String? parentId) =>
      fakeCall(() => _store.saveCategory(id, name, parentId));

  @override
  Future<void> deleteCategory(String id) =>
      fakeCall(() => _store.deleteCategory(id));

  @override
  Future<List<AuctionSession>> sessions() => fakeCall(_store.adminSessions);

  @override
  Future<(AuctionSession, List<Lot>)> session(String id) => fakeCall(() {
    final c = _store.catalogue(id);
    return (c.session, c.lots);
  });

  @override
  Future<AuctionSession> saveSession(String? id, AuctionSession draft) =>
      fakeCall(() => _store.saveSession(id, draft));

  @override
  Future<(AuctionSession, List<Lot>)> setLots(String id, List<String> lotIds) =>
      fakeCall(() {
        final c = _store.setSessionLots(id, lotIds);
        return (c.session, c.lots);
      });

  @override
  Future<AuctionSession> publish(String id) =>
      fakeCall(() => _store.publishSession(id));

  @override
  Future<AuctionSession> pause(String id) =>
      fakeCall(() => _store.pauseSession(id));

  @override
  Future<AuctionSession> resume(String id) =>
      fakeCall(() => _store.resumeSession(id));

  @override
  Future<List<Lot>> lots({LotStatus? status}) =>
      fakeCall(() => _store.adminLots(status: status));

  @override
  Future<Lot> cancelLot(String id, String reason) =>
      fakeCall(() => _store.cancelLot(id, reason));

  @override
  Future<SessionState> sessionState(String id) =>
      fakeCall(() => _store.sessionState(id), ms: 60);

  @override
  Future<SystemConfig> config() => fakeCall(() => _store.config);

  @override
  Future<SystemConfig> updateConfig(SystemConfig config) =>
      fakeCall(() => _store.updateConfig(config));

  @override
  Future<List<Withdrawal>> withdrawals() =>
      fakeCall(() => List.of(_store.withdrawals));

  @override
  Future<Withdrawal> completeWithdrawal(String id, WithdrawalReceipt receipt) =>
      fakeCall(() => _store.completeWithdrawal(id, receipt));

  @override
  Future<List<ActivityLog>> activityLogs() => fakeCall(_store.allActivityLogs);

  @override
  Future<List<Order>> disputes() => fakeCall(_store.disputes);

  @override
  Future<Order> resolveDispute(
    String id, {
    required bool refund,
    String? note,
  }) => fakeCall(() => _store.resolveDispute(id, refund: refund, note: note));
}
