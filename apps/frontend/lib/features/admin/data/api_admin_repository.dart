import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/admin/domain/admin_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class ApiAdminRepository implements AdminRepository {
  ApiAdminRepository(this._client);

  final api.RestClient _client;

  api.AdminClient get _admin => _client.admin;

  (AuctionSession, List<Lot>) _catalogue(api.SessionCatalogueDto d) =>
      (d.session.toDomain(), d.lots.map((e) => e.toDomain()).toList());

  @override
  Future<Dashboard> dashboard() =>
      guardApi(() async => (await _admin.adminDashboard()).toDomain());

  @override
  Future<List<Listing>> listings({ListingStatus? status}) => guardApi(
    () async => (await _admin.adminListListings(
      size: 100,
      status: status == null
          ? null
          : toApiEnum(api.ListingStatus.values, status),
    )).toDomain().items,
  );

  @override
  Future<Listing> reviewListing(
    String id, {
    required bool approve,
    String? reason,
  }) => guardApi(
    () async => (await _admin.adminReviewListing(
      id: id,
      body: api.ApprovalRequest(approve: approve, reason: reason),
    )).toDomain(),
  );

  @override
  Future<List<AppUser>> users({String? q}) => guardApi(
    () async => (await _admin.adminListUsers(
      size: 100,
      q: q,
    )).items.map((e) => e.toDomain()).toList(),
  );

  @override
  Future<AppUser> setLocked(
    String id, {
    required bool locked,
    String? reason,
  }) => guardApi(
    () async => (await _admin.adminLockUser(
      id: id,
      body: api.LockUserRequest(locked: locked, reason: reason),
    )).toDomain(),
  );

  @override
  Future<List<Category>> categories() => guardApi(
    () async => (await _client.categories.listCategories())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<Category> saveCategory(String? id, String name, String? parentId) =>
      guardApi(() async {
        final body = api.CategoryRequest(name: name, parentId: parentId);
        final dto = id == null
            ? await _admin.adminCreateCategory(body: body)
            : await _admin.adminUpdateCategory(id: id, body: body);
        return dto.toDomain();
      });

  @override
  Future<void> deleteCategory(String id) =>
      guardApi(() => _admin.adminDeleteCategory(id: id));

  @override
  Future<List<AuctionSession>> sessions() => guardApi(
    () async =>
        (await _admin.adminListSessions()).map((e) => e.toDomain()).toList(),
  );

  @override
  Future<(AuctionSession, List<Lot>)> session(String id) => guardApi(
    () async => _catalogue(await _client.auctions.getSessionCatalogue(id: id)),
  );

  @override
  Future<AuctionSession> saveSession(String? id, AuctionSession draft) =>
      guardApi(() async {
        final body = draft.toRequest();
        final dto = id == null
            ? await _admin.adminCreateSession(body: body)
            : await _admin.adminUpdateSession(id: id, body: body);
        return dto.toDomain();
      });

  @override
  Future<(AuctionSession, List<Lot>)> setLots(String id, List<String> lotIds) =>
      guardApi(
        () async => _catalogue(
          await _admin.adminSetSessionLots(
            id: id,
            body: api.SessionLotsRequest(lotIds: lotIds),
          ),
        ),
      );

  @override
  Future<AuctionSession> publish(String id) => guardApi(
    () async => (await _admin.adminPublishSession(id: id)).toDomain(),
  );

  @override
  Future<AuctionSession> pause(String id) =>
      guardApi(() async => (await _admin.adminPauseSession(id: id)).toDomain());

  @override
  Future<AuctionSession> resume(String id) => guardApi(
    () async => (await _admin.adminResumeSession(id: id)).toDomain(),
  );

  @override
  Future<List<Lot>> lots({LotStatus? status}) => guardApi(
    () async => (await _admin.adminListLots(
      status: status == null ? null : toApiEnum(api.LotStatus.values, status),
    )).map((e) => e.toDomain()).toList(),
  );

  @override
  Future<Lot> cancelLot(String id, String reason) => guardApi(
    () async => (await _admin.adminCancelLot(
      id: id,
      body: api.ReasonRequest(reason: reason),
    )).toDomain(),
  );

  @override
  Future<SessionState> sessionState(String id) => guardApi(
    () async => (await _client.auctions.getSessionState(id: id)).toDomain(),
  );

  @override
  Future<SystemConfig> config() =>
      guardApi(() async => (await _admin.adminGetConfig()).toDomain());

  @override
  Future<SystemConfig> updateConfig(SystemConfig config) => guardApi(
    () async =>
        (await _admin.adminUpdateConfig(body: config.toDto())).toDomain(),
  );

  @override
  Future<List<Withdrawal>> withdrawals() => guardApi(
    () async =>
        (await _admin.adminListWithdrawals()).map((e) => e.toDomain()).toList(),
  );

  @override
  Future<Withdrawal> completeWithdrawal(String id, WithdrawalReceipt receipt) =>
      guardApi(
        () async => (await _admin.adminCompleteWithdrawal(
          id: id,
          body: receipt.toDto(),
        )).toDomain(),
      );

  @override
  Future<List<ActivityLog>> activityLogs() => guardApi(
    () async => (await _admin.adminListActivityLogs())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<List<Order>> resolvedDisputes() => guardApi(
    () async =>
        (await _admin.adminListDisputes(resolved: true))
            .map((e) => e.toDomain())
            .toList(),
  );

  @override
  Future<List<Order>> disputes() => guardApi(
    () async =>
        (await _admin.adminListDisputes()).map((e) => e.toDomain()).toList(),
  );

  @override
  Future<Order> resolveDispute(
    String id, {
    required bool refund,
    String? note,
  }) => guardApi(
    () async => (await _admin.adminResolveDispute(
      id: id,
      body: api.ReturnDecisionRequest(accept: refund, note: note),
    )).toDomain(),
  );
}
