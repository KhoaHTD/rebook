import 'package:book_marketplace/features/staff/domain/staff_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

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
  Future<Order> advanceOrder(String id, {String? trackingCode}) =>
      fakeCall(() => _store.advanceAuctionOrder(id, trackingCode));
}
