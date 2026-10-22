import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/staff/domain/staff_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

class ApiStaffRepository implements StaffRepository {
  ApiStaffRepository(this._client);

  final api.RestClient _client;

  @override
  Future<List<Consignment>> consignments({ConsignmentStatus? status}) =>
      guardApi(
        () async => (await _client.staff.staffListConsignments(
          status: status == null
              ? null
              : toApiEnum(api.ConsignmentStatus.values, status),
        )).map((e) => e.toDomain()).toList(),
      );

  @override
  Future<Consignment> consignment(String id) => guardApi(
    () async => (await _client.consignments.getConsignment(id: id)).toDomain(),
  );

  @override
  Future<Consignment> preReview(
    String id, {
    required bool approve,
    String? reason,
  }) => guardApi(
    () async => (await _client.staff.staffPreReview(
      id: id,
      body: api.ApprovalRequest(approve: approve, reason: reason),
    )).toDomain(),
  );

  @override
  Future<List<Consignment>> appointments() => guardApi(
    () async => (await _client.staff.staffListAppointments())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<Consignment> checkIn(
    String code, {
    required List<String> receiptImageUrls,
    String? shelfCode,
  }) => guardApi(
    () async => (await _client.staff.staffCheckIn(
      body: api.CheckInRequest(
        appointmentCode: code,
        receiptImageUrls: receiptImageUrls,
        shelfCode: shelfCode,
      ),
    )).toDomain(),
  );

  @override
  Future<Consignment> submitInspection(String id, InspectionDraft draft) =>
      guardApi(
        () async => (await _client.staff.staffSubmitInspection(
          id: id,
          body: draft.toRequest(),
        )).toDomain(),
      );

  @override
  Future<List<WarehouseItem>> warehouse({WarehouseStatus? status}) => guardApi(
    () async => (await _client.staff.staffListWarehouse(
      status: status == null
          ? null
          : toApiEnum(api.WarehouseStatus.values, status),
    )).map((e) => e.toDomain()).toList(),
  );

  @override
  Future<WarehouseItem> updateWarehouse(
    String id, {
    String? shelfCode,
    WarehouseStatus? status,
  }) => guardApi(
    () async => (await _client.staff.staffUpdateWarehouseItem(
      id: id,
      body: api.WarehouseUpdateRequest(
        shelfCode: shelfCode,
        status: status == null
            ? null
            : toApiEnum(api.WarehouseStatus.values, status),
      ),
    )).toDomain(),
  );

  @override
  Future<List<Order>> auctionOrders() => guardApi(
    () async => (await _client.staff.staffListAuctionOrders())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<Order> advanceOrder(String id, {String? trackingCode}) => guardApi(
    () async => (await _client.staff.staffAdvanceOrder(
      id: id,
      body: api.ShipRequest(trackingCode: trackingCode),
    )).toDomain(),
  );
}
