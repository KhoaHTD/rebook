import 'dart:math' as math;

import 'package:book_marketplace/features/admin/domain/admin_report.dart';
import 'package:book_marketplace/features/admin/domain/cod_pending.dart';
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

  /// Số liệu mẫu ổn định theo ngày (cùng một ngày luôn ra cùng số), có nhịp tuần: cuối tuần đông hơn.
  @override
  Future<AdminReport> report(DateTime from, DateTime to) => fakeCall(() {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final days = <ReportDay>[];
    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final r = math.Random(d.year * 10000 + d.month * 100 + d.day);
      final weekend = d.weekday >= 6 ? 1.35 : 1.0;
      final orders = ((6 + r.nextInt(9)) * weekend).round();
      days.add(
        ReportDay(
          date: d,
          orders: orders,
          gmv: orders * (90000 + r.nextInt(120000)),
          newUsers: 1 + r.nextInt(6),
        ),
      );
    }
    final gmv = days.fold<int>(0, (a, d) => a + d.gmv);
    final orders = days.fold<int>(0, (a, d) => a + d.orders);
    final completed = (orders * 0.74).round();
    final cancelled = (orders * 0.08).round();
    const names = [
      'Văn học Việt Nam',
      'Văn học nước ngoài',
      'Kỹ năng sống',
      'Kinh tế',
      'Thiếu nhi',
      'Sách hiếm',
    ];
    const shares = [0.31, 0.24, 0.17, 0.12, 0.09, 0.07];
    return AdminReport(
      from: start,
      to: end,
      gmv: gmv,
      revenue: (gmv * 0.74).round(),
      platformFees: (gmv * 0.74 * 0.08).round(),
      orders: orders,
      completedOrders: completed,
      cancelledOrders: cancelled,
      auctionOrders: (orders * 0.12).round(),
      newUsers: days.fold<int>(0, (a, d) => a + d.newUsers),
      days: days,
      categories: [
        for (var i = 0; i < names.length; i++)
          ReportCategory(name: names[i], amount: (gmv * shares[i]).round()),
      ],
      statuses: [
        ReportStatusCount(status: OrderStatus.completed, count: completed),
        ReportStatusCount(
          status: OrderStatus.shipping,
          count: (orders * 0.09).round(),
        ),
        ReportStatusCount(
          status: OrderStatus.preparing,
          count: (orders * 0.06).round(),
        ),
        ReportStatusCount(
          status: OrderStatus.pendingConfirm,
          count: (orders * 0.03).round(),
        ),
        ReportStatusCount(status: OrderStatus.cancelled, count: cancelled),
      ],
    );
  });

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
  Future<AppUser> setRole(String id, UserRole role) =>
      fakeCall(() => _store.setRole(id, role));

  @override
  Future<void> chargeback(String userId, int amount, String reason) =>
      fakeCall(() {});

  @override
  Future<AppUser> liftAuctionBan(String id) =>
      fakeCall(() => _store.liftAuctionBan(id));

  @override
  Future<AuctionSession> cancelSession(String id, String reason) =>
      fakeCall(() => _store.cancelSessionByAdmin(id, reason));

  @override
  Future<AuctionSession> startNow(String id) =>
      fakeCall(() => _store.startSessionNow(id));

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
  Future<List<Order>> resolvedDisputes() => fakeCall(_store.resolvedDisputes);

  @override
  Future<Order> resolveDispute(
    String id, {
    required bool refund,
    String? note,
  }) => fakeCall(() => _store.resolveDispute(id, refund: refund, note: note));

  // Dữ liệu giả không có đối soát COD với hãng vận chuyển.
  @override
  Future<List<CodPending>> codPending() => fakeCall(() => <CodPending>[]);

  @override
  Future<void> remitCod(String orderId, int amount) async {}
}
