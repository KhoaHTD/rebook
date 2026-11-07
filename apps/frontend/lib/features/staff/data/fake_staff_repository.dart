import 'package:book_marketplace/shared/domain/transit_order.dart';
import 'package:book_marketplace/features/staff/domain/staff_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/incident.dart';

class FakeStaffRepository implements StaffRepository {
  FakeStaffRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<Consignment>> consignments({ConsignmentStatus? status}) =>
      fakeCall(() => _store.staffConsignments(status: status));

  @override
  Future<Consignment> consignment(String id) =>
      fakeCall(() => _store.consignment(id));

  @override
  Future<Consignment> preReview(
    String id, {
    required bool approve,
    String? reason,
  }) => fakeCall(() => _store.preReview(id, approve: approve, reason: reason));

  @override
  Future<List<Consignment>> appointments() => fakeCall(_store.appointments);

  @override
  Future<Consignment> checkIn(
    String code, {
    required List<String> receiptImageUrls,
    String? shelfCode,
  }) => fakeCall(() => _store.checkIn(code, receiptImageUrls, shelfCode));

  @override
  Future<Consignment> submitInspection(String id, InspectionDraft draft) =>
      fakeCall(() => _store.submitInspection(id, draft), ms: 500);

  @override
  Future<List<WarehouseItem>> warehouse({WarehouseStatus? status}) =>
      fakeCall(() => _store.warehouseItems(status: status));

  @override
  Future<WarehouseItem> updateWarehouse(
    String id, {
    String? shelfCode,
    WarehouseStatus? status,
  }) => fakeCall(
    () => _store.updateWarehouse(id, shelf: shelfCode, status: status),
  );

  @override
  Future<List<Order>> auctionOrders() => fakeCall(_store.auctionOrders);

  @override
  Future<Order> order(String id) => fakeCall(() => _store.order(id));

  @override
  Future<Order> advanceOrder(String id, {String? trackingCode}) =>
      fakeCall(() => _store.advanceAuctionOrder(id, trackingCode));

  @override
  Future<List<TransitOrder>> inTransit() => fakeCall(_store.transitOrders);

  @override
  Future<void> carrierDelivered(String id) =>
      fakeCall(() => _store.markDelivered(id));

  @override
  Future<void> carrierFailed(
    String id,
    String reason,
    DeliveryFaultKind fault,
  ) => fakeCall(() => _store.markDeliveryFailed(id, reason));

  @override
  Future<void> auctionDeliveryFailed(
    String id,
    String reason,
    DeliveryFaultKind fault,
  ) => fakeCall(() => _store.markDeliveryFailed(id, reason));

  @override
  Future<void> auctionReturnDecision(
    String id, {
    required bool accept,
    String? note,
  }) => fakeCall(() => _store.decideReturn(id, accept: accept, note: note));

  @override
  Future<void> auctionReturnReceived(String id) =>
      fakeCall(() => _store.confirmReturnReceived(id));

  @override
  Future<WarehouseIncident> reportIncident(
    String warehouseItemId,
    IncidentType type,
    String description,
  ) =>
      fakeCall(() => _store.reportIncident(warehouseItemId, type, description));

  @override
  Future<List<WarehouseIncident>> incidents() =>
      fakeCall(() => List.of(_store.incidents.reversed));

  @override
  Future<WarehouseIncident> approveIncident(
    String id, {
    int sellerPercent = 100,
  }) => fakeCall(() => _store.decideIncident(id, true, sellerPercent, null));

  @override
  Future<WarehouseIncident> rejectIncident(String id, String reason) =>
      fakeCall(() => _store.decideIncident(id, false, 0, reason));

  @override
  Future<List<InspectingLot>> inspectingLots() =>
      fakeCall(() => List.of(_store.inspectingLots));

  @override
  Future<void> reinspect(
    String lotId, {
    required bool passed,
    required String report,
  }) => fakeCall(
    () => _store.inspectingLots.removeWhere((l) => l.lotId == lotId),
  );
}
