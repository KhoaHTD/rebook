import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/staff/domain/staff_repository.dart';
import 'package:book_marketplace/shared/domain/transit_order.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/incident.dart';

class ApiStaffRepository implements StaffRepository {
  ApiStaffRepository(this._client);

  final api.RestClient _client;

  @override
  Future<List<Consignment>> consignments({ConsignmentStatus? status}) =>
      guardApi(() async {
        final res = await _client.consignment.getStaffConsignments(
          status: status == null ? null : consignmentStatusToApi(status),
          size: 100,
        );
        return [for (final c in res.items.orEmpty) c.toDomain()];
      });

  @override
  Future<Consignment> consignment(String id) => guardApi(
    () async =>
        (await _client.consignment.getConsignmentsId(id: apiId(id))).toDomain(),
  );

  @override
  Future<Consignment> preReview(
    String id, {
    required bool approve,
    String? reason,
  }) => guardApi(
    () async => (await _client.consignment.postStaffConsignmentsIdReview(
      id: apiId(id),
      body: api.ConsignmentReviewRequest(approve: approve, note: reason),
    )).toDomain(),
  );

  @override
  Future<List<Consignment>> appointments() => guardApi(
    () async => [
      for (final c in await _client.consignment.getStaffAppointments())
        c.toDomain(),
    ],
  );

  /// Nhận sách theo mã lịch hẹn: tra mã ra ký gửi, rồi check-in ký gửi đó.
  @override
  Future<Consignment> checkIn(
    String code, {
    required List<String> receiptImageUrls,
    String? shelfCode,
  }) => guardApi(() async {
    final found = await _client.consignment.getStaffAppointmentsCode(
      code: code,
    );
    final res = await _client.consignment.postStaffConsignmentsIdCheckIn(
      id: found.id ?? 0,
      body: api.CheckInRequest(
        shelfCode: shelfCode,
        photoUrls: receiptImageUrls,
      ),
    );
    return res.toDomain();
  });

  @override
  Future<Consignment> submitInspection(String id, InspectionDraft draft) =>
      guardApi(
        () async =>
            (await _client.consignment.postStaffConsignmentsIdInspection(
              id: apiId(id),
              body: draft.toRequest(),
            )).toDomain(),
      );

  @override
  Future<List<WarehouseItem>> warehouse({WarehouseStatus? status}) =>
      guardApi(() async {
        final res = await _client.consignment.getStaffWarehouse(
          status: status == null ? null : warehouseStatusToApi(status),
          size: 100,
        );
        return [for (final w in res.items.orEmpty) w.toDomain()];
      });

  /// Đổi kệ = `PUT`, trả sách về = `POST …/return`. Backend không có các chuyển
  /// trạng thái kho khác bằng tay (đặt giữ chỗ / xuất kho do hệ thống tự làm).
  @override
  Future<WarehouseItem> updateWarehouse(
    String id, {
    String? shelfCode,
    WarehouseStatus? status,
  }) => guardApi(() async {
    final itemId = apiId(id);
    api.WarehouseResponse? res;
    if (shelfCode != null) {
      res = await _client.consignment.putStaffWarehouseId(
        id: itemId,
        body: api.ShelfRequest(shelfCode: shelfCode),
      );
    }
    if (status == WarehouseStatus.returned) {
      res = await _client.consignment.postStaffWarehouseIdReturn(id: itemId);
    }
    if (res == null) {
      throw const ServerException(
        409,
        code: ErrorCodes.invalidTransition,
        message: 'Backend không hỗ trợ đổi sang trạng thái kho này.',
      );
    }
    return res.toDomain();
  });

  @override
  Future<List<Order>> auctionOrders() => guardApi(() async {
    final res = await _client.orderManagement.getStaffOrders(size: 100);
    return [for (final o in res.items.orEmpty) o.toDomain()];
  });

  /// Đẩy đơn đấu giá sang bước kế: xác nhận → giao vận chuyển → đã giao.
  @override
  Future<Order> order(String id) => guardApi(
    () async => (await _client.order.getOrdersId(id: apiId(id))).toDomain(),
  );

  @override
  Future<Order> advanceOrder(
    String id, {
    String? trackingCode,
  }) => guardApi(() async {
    final orderId = apiId(id);
    final current = await _client.order.getOrdersId(id: orderId);
    final mgmt = _client.orderManagement;
    final next = switch (current.status) {
      api.OrderStatus.pendingConfirm => mgmt.postStaffOrdersIdConfirm(
        id: orderId,
      ),
      api.OrderStatus.preparing => mgmt.postStaffOrdersIdShip(
        id: orderId,
        body: api.ShipRequest(trackingCode: trackingCode),
      ),
      api.OrderStatus.shipping => mgmt.postStaffOrdersIdDelivered(id: orderId),
      _ => throw const ServerException(409, code: ErrorCodes.invalidTransition),
    };
    return (await next).toDomain();
  });

  @override
  Future<List<TransitOrder>> inTransit() => guardApi(() async {
    final res = await _client.orderManagement.getStaffOrdersInTransit(
      size: 100,
    );
    return [
      for (final o in res.items.orEmpty)
        TransitOrder(
          id: '${o.orderId ?? 0}',
          code: o.code ?? '',
          shopName: o.shopName ?? '',
          isCod: o.paymentMethod == api.PaymentMethod.cod,
          total: o.total?.round() ?? 0,
          trackingCode: o.trackingCode,
          shippedAt: o.shippedAt,
          overdue: o.overdue ?? false,
        ),
    ];
  });

  @override
  Future<void> carrierDelivered(String id) => guardApi(
    () => _client.orderManagement.postStaffOrdersIdCarrierDelivered(
      id: apiId(id),
    ),
  );

  @override
  Future<void> carrierFailed(
    String id,
    String reason,
    DeliveryFaultKind fault,
  ) => guardApi(
    () => _client.orderManagement.postStaffOrdersIdCarrierFailed(
      id: apiId(id),
      body: api.DeliveryFailedRequest(
        reason: reason,
        fault: switch (fault) {
          DeliveryFaultKind.buyer => api.DeliveryFault.buyer,
          DeliveryFaultKind.carrier => api.DeliveryFault.carrier,
          DeliveryFaultKind.shop => api.DeliveryFault.shop,
        },
      ),
    ),
  );

  @override
  Future<void> auctionDeliveryFailed(
    String id,
    String reason,
    DeliveryFaultKind fault,
  ) => guardApi(
    () => _client.orderManagement.postStaffOrdersIdDeliveryFailed(
      id: apiId(id),
      body: api.DeliveryFailedRequest(
        reason: reason,
        fault: switch (fault) {
          DeliveryFaultKind.buyer => api.DeliveryFault.buyer,
          DeliveryFaultKind.carrier => api.DeliveryFault.carrier,
          DeliveryFaultKind.shop => api.DeliveryFault.shop,
        },
      ),
    ),
  );

  @override
  Future<void> auctionReturnDecision(
    String id, {
    required bool accept,
    String? note,
  }) => guardApi(
    () => _client.orderManagement.postStaffOrdersIdReturnDecision(
      id: apiId(id),
      body: api.DecisionRequest(approve: accept, note: note),
    ),
  );

  @override
  Future<void> auctionReturnReceived(String id) => guardApi(
    () =>
        _client.orderManagement.postStaffOrdersIdReturnReceived(id: apiId(id)),
  );

  WarehouseIncident _incident(api.IncidentResponse i) => WarehouseIncident(
    id: '${i.id ?? 0}',
    bookTitle: i.bookTitle ?? '',
    consignmentCode: i.consignmentCode,
    type: i.type == api.IncidentType.damaged
        ? IncidentType.damaged
        : IncidentType.lost,
    description: i.description ?? '',
    status: switch (i.status) {
      api.IncidentStatus.approved => IncidentStatus.approved,
      api.IncidentStatus.rejected => IncidentStatus.rejected,
      _ => IncidentStatus.pending,
    },
    createdAt: i.createdAt ?? DateTime.now(),
    sellerPercent: i.sellerPercent,
    sellerAmount: i.sellerAmount?.round(),
    buyerAmount: i.buyerAmount?.round(),
    decisionNote: i.decisionNote,
  );

  @override
  Future<WarehouseIncident> reportIncident(
    String warehouseItemId,
    IncidentType type,
    String description,
  ) => guardApi(
    () async => _incident(
      await _client.consignment.postStaffWarehouseIdIncidents(
        id: apiId(warehouseItemId),
        body: api.IncidentRequest(
          type: type == IncidentType.damaged
              ? api.IncidentType.damaged
              : api.IncidentType.lost,
          description: description,
        ),
      ),
    ),
  );

  @override
  Future<List<WarehouseIncident>> incidents() => guardApi(() async {
    final res = await _client.consignment.getStaffWarehouseIncidents(size: 100);
    return [for (final i in res.items.orEmpty) _incident(i)];
  });

  @override
  Future<WarehouseIncident> approveIncident(
    String id, {
    int sellerPercent = 100,
  }) => guardApi(
    () async => _incident(
      await _client.consignment.postAdminWarehouseIncidentsIdApprove(
        id: apiId(id),
        body: api.IncidentDecisionRequest(sellerPercent: sellerPercent),
      ),
    ),
  );

  @override
  Future<WarehouseIncident> rejectIncident(String id, String reason) =>
      guardApi(
        () async => _incident(
          await _client.consignment.postAdminWarehouseIncidentsIdReject(
            id: apiId(id),
            body: api.IncidentRejectRequest(reason: reason),
          ),
        ),
      );

  @override
  Future<List<InspectingLot>> inspectingLots() => guardApi(() async {
    final res = await _client.consignment.getStaffLotsInspecting(size: 100);
    return [
      for (final l in res.items.orEmpty)
        InspectingLot(
          lotId: '${l.lotId ?? 0}',
          bookTitle: l.bookTitle ?? '',
          consignmentCode: l.consignmentCode,
          hammerPrice: l.hammerPrice?.round(),
          closedAt: l.closedAt,
        ),
    ];
  });

  @override
  Future<void> reinspect(
    String lotId, {
    required bool passed,
    required String report,
  }) => guardApi(() async {
    await _client.consignment.postStaffLotsIdReinspect(
      id: apiId(lotId),
      body: api.ReinspectRequest(passed: passed, report: report),
    );
  });
}
