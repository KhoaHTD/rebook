import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/admin/domain/admin_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/data/session_loader.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class ApiAdminRepository implements AdminRepository {
  ApiAdminRepository(this._client);

  final api.RestClient _client;

  @override
  Future<Dashboard> dashboard() => guardApi(() async {
    final results = await Future.wait([
      _client.admin.getAdminDashboard(),
      _client.admin.getAdminUsers(size: 1),
      _client.consignment.getStaffConsignments(
        status: api.ConsignmentStatus.submitted,
        size: 1,
      ),
    ]);
    return (results[0] as api.DashboardResponse).toDomain(
      users: (results[1] as api.PageResponseUserResponse).totalItems ?? 0,
      pendingConsignments:
          (results[2] as api.PageResponseConsignmentResponse).totalItems ?? 0,
    );
  });

  // ── Tin đăng ──

  /// Backend chỉ có danh sách "chờ duyệt" cho admin; trạng thái khác lấy từ danh sách công khai.
  @override
  Future<List<Listing>> listings({ListingStatus? status}) => guardApi(() async {
    final pendingOnly = status == null || status == ListingStatus.pendingReview;
    final res = pendingOnly
        ? await _client.catalog.getAdminListingsPending(size: 100)
        : await _client.catalog.getListings(size: 100);
    final all = <Listing>[for (final l in res.items.orEmpty) l.toDomain()];
    return pendingOnly ? all : all.where((l) => l.status == status).toList();
  });

  @override
  Future<Listing> reviewListing(
    String id, {
    required bool approve,
    String? reason,
  }) => guardApi(() async {
    final listingId = apiId(id);
    final res = approve
        ? await _client.catalog.postAdminListingsIdApprove(id: listingId)
        : await _client.catalog.postAdminListingsIdReject(
            id: listingId,
            body: api.RejectRequest(reason: reason ?? ''),
          );
    return res.toDomain();
  });

  // ── Người dùng ──

  @override
  Future<List<AppUser>> users({String? q}) => guardApi(() async {
    final res = await _client.admin.getAdminUsers(q: q, size: 100);
    return [for (final u in res.items.orEmpty) u.toDomain()];
  });

  @override
  Future<AppUser> setLocked(
    String id, {
    required bool locked,
    String? reason,
  }) => guardApi(() async {
    final userId = apiId(id);
    final res = locked
        ? await _client.admin.postAdminUsersIdLock(
            id: userId,
            body: api.LockRequest(reason: reason ?? ''),
          )
        : await _client.admin.postAdminUsersIdUnlock(id: userId);
    return res.toDomain();
  });

  // ── Danh mục ──

  @override
  Future<List<Category>> categories() => guardApi(
    () async => flattenCategories(await _client.catalog.getCategories()),
  );

  @override
  Future<Category> saveCategory(String? id, String name, String? parentId) =>
      guardApi(() async {
        final body = api.CategoryRequest(
          name: name,
          slug: _slugify(name),
          parentId: int.tryParse(parentId ?? ''),
        );
        final res = id == null
            ? await _client.catalog.postAdminCategories(body: body)
            : await _client.catalog.putAdminCategoriesId(
                id: apiId(id),
                body: body,
              );
        return Category(
          id: '${res.id}',
          name: res.name ?? name,
          parentId: res.parentId == null ? null : '${res.parentId}',
        );
      });

  @override
  Future<void> deleteCategory(String id) =>
      guardApi(() => _client.catalog.deleteAdminCategoriesId(id: apiId(id)));

  // ── Phiên đấu giá ──

  @override
  Future<List<AuctionSession>> sessions() => guardApi(() async {
    final res = await _client.auction.getAdminSessions(size: 100);
    return [for (final s in res.items.orEmpty) s.toDomain()];
  });

  @override
  Future<(AuctionSession, List<Lot>)> session(String id) => guardApi(() async {
    final detail = await _client.auction.getAdminSessionsId(id: apiId(id));
    return (detail.sessionToDomain(), detail.lotsToDomain());
  });

  @override
  Future<AuctionSession> saveSession(String? id, AuctionSession draft) =>
      guardApi(() async {
        final res = id == null
            ? await _client.auction.postAdminSessions(body: draft.toRequest())
            : await _client.auction.putAdminSessionsId(
                id: apiId(id),
                body: draft.toRequest(),
              );
        return res.toDomain(
          lotDurationSec: draft.lotDurationSec,
          softCloseSec: draft.softCloseSec,
        );
      });

  @override
  Future<(AuctionSession, List<Lot>)> setLots(String id, List<String> lotIds) =>
      guardApi(() async {
        final detail = await _client.auction.putAdminSessionsIdLots(
          id: apiId(id),
          body: api.AssignLotsRequest(lotIds: lotIds.map(apiId).toList()),
        );
        return (detail.sessionToDomain(), detail.lotsToDomain());
      });

  @override
  Future<AuctionSession> publish(String id) => guardApi(
    () async =>
        (await _client.auction.postAdminSessionsIdPublish(id: apiId(id)))
            .toDomain(),
  );

  @override
  Future<AuctionSession> pause(String id) => guardApi(
    () async =>
        (await _client.auction.postStaffSessionsIdPause(id: apiId(id)))
            .toDomain(),
  );

  @override
  Future<AuctionSession> resume(String id) => guardApi(
    () async =>
        (await _client.auction.postStaffSessionsIdResume(id: apiId(id)))
            .toDomain(),
  );

  /// Backend chỉ liệt kê lô *chờ xếp phiên* cho admin (`/admin/lots/ready`);
  /// lọc theo trạng thái khác thì không có dữ liệu để trả.
  @override
  Future<List<Lot>> lots({LotStatus? status}) => guardApi(() async {
    if (status != null && status != LotStatus.ready) return const [];
    final res = await _client.auction.getAdminLotsReady(size: 100);
    return [for (final l in res.items.orEmpty) l.toDomain()];
  });

  @override
  Future<Lot> cancelLot(String id, String reason) => guardApi(() async {
    final lotId = apiId(id);
    await _client.auction.postStaffLotsIdCancel(
      id: lotId,
      body: api.ReasonRequest(reason: reason),
    );
    return (await _client.auction.getLotsId(id: lotId)).toDomain();
  });

  @override
  Future<SessionState> sessionState(String id) =>
      guardApi(() => loadSessionState(_client, id));

  // ── Cấu hình, tiền ──

  @override
  Future<SystemConfig> config() => guardApi(
    () async => systemConfigFromList(await _client.admin.getAdminConfigs()),
  );

  @override
  Future<SystemConfig> updateConfig(SystemConfig config) => guardApi(() async {
    final current = systemConfigFromList(await _client.admin.getAdminConfigs());
    final before = systemConfigToValues(current);
    for (final e in systemConfigToValues(config).entries) {
      if (before[e.key] == e.value) continue;
      await _client.admin.putAdminConfigsKey(
        key: e.key,
        body: api.ConfigRequest(value: e.value),
      );
    }
    return systemConfigFromList(await _client.admin.getAdminConfigs());
  });

  @override
  Future<List<Withdrawal>> withdrawals() => guardApi(() async {
    final res = await _client.admin.getAdminWithdrawals(size: 100);
    return [for (final w in res.items.orEmpty) w.toDomain()];
  });

  @override
  Future<Withdrawal> completeWithdrawal(String id) => guardApi(
    () async => (await _client.admin.postAdminWithdrawalsId(
      id: apiId(id),
      body: const api.ProcessRequest(approve: true),
    )).toDomain(),
  );

  /// Backend liệt kê khiếu nại theo yêu cầu trả hàng; app hiển thị theo đơn nên tra đơn của từng yêu cầu.
  @override
  Future<List<Order>> disputes() => guardApi(() async {
    final res = await _client.orderManagement.getAdminDisputes(size: 100);
    return Future.wait([
      for (final r in res.items ?? const <api.ReturnResponse>[])
        _client.order.getOrdersId(id: r.orderId ?? 0).then((o) => o.toDomain()),
    ]);
  });

  @override
  Future<Order> resolveDispute(
    String id, {
    required bool refund,
    String? note,
  }) => guardApi(
    () async => (await _client.orderManagement.postAdminDisputesOrderIdResolve(
      orderId: apiId(id),
      body: api.DecisionRequest(approve: refund, note: note),
    )).toDomain(),
  );
}

/// "Sách thiếu nhi" → "sach-thieu-nhi" (backend bắt buộc `slug` duy nhất).
String _slugify(String name) {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  var s = name.toLowerCase();
  groups.forEach((plain, accented) {
    for (final ch in accented.split('')) {
      s = s.replaceAll(ch, plain);
    }
  });
  return s
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
