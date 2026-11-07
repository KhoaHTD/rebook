import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/staff/data/staff_repository_provider.dart';
import 'package:book_marketplace/shared/domain/transit_order.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/incident.dart';

part 'staff_providers.g.dart';

@riverpod
Future<List<Consignment>> staffConsignments(Ref ref) {
  ref.watchArea(DataArea.consignments);
  return ref.watch(staffRepositoryProvider).consignments();
}

@riverpod
Future<Consignment> staffConsignment(Ref ref, String id) {
  ref.watchArea(DataArea.consignments);
  return ref.watch(staffRepositoryProvider).consignment(id);
}

@riverpod
Future<List<Consignment>> staffAppointments(Ref ref) {
  ref.watchArea(DataArea.consignments);
  return ref.watch(staffRepositoryProvider).appointments();
}

@riverpod
Future<List<WarehouseItem>> warehouseItems(Ref ref) {
  ref
    ..watchArea(DataArea.warehouse)
    ..watchArea(DataArea.consignments);
  return ref.watch(staffRepositoryProvider).warehouse();
}

@riverpod
Future<Order> staffOrder(Ref ref, String id) =>
    ref.watch(staffRepositoryProvider).order(id);

@riverpod
Future<List<Order>> staffAuctionOrders(Ref ref) {
  ref.watchArea(DataArea.orders);
  return ref.watch(staffRepositoryProvider).auctionOrders();
}

@riverpod
Future<List<TransitOrder>> staffInTransit(Ref ref) {
  ref.watchArea(DataArea.orders);
  return ref.watch(staffRepositoryProvider).inTransit();
}

@riverpod
Future<List<WarehouseIncident>> warehouseIncidents(Ref ref) {
  ref.watchArea(DataArea.warehouse);
  return ref.watch(staffRepositoryProvider).incidents();
}

@riverpod
Future<List<InspectingLot>> inspectingLots(Ref ref) {
  ref.watchArea(DataArea.warehouse);
  return ref.watch(staffRepositoryProvider).inspectingLots();
}

@riverpod
class StaffActions extends _$StaffActions {
  @override
  FutureOr<void> build() {}

  Future<T?> _run<T>(Future<T> Function() action, List<String> areas) async {
    state = const AsyncLoading();
    T? result;
    state = await AsyncValue.guard(() async {
      result = await action();
    });
    if (!state.hasError) {
      final changes = ref.read(dataChangesProvider.notifier);
      for (final a in areas) {
        changes.bump(a);
      }
    }
    return result;
  }

  Future<Consignment?> preReview(
    String id, {
    required bool approve,
    String? reason,
  }) => _run(
    () => ref
        .read(staffRepositoryProvider)
        .preReview(id, approve: approve, reason: reason),
    [DataArea.consignments],
  );

  Future<Consignment?> checkIn(
    String code, {
    required List<String> receipts,
    String? shelf,
  }) => _run(
    () => ref
        .read(staffRepositoryProvider)
        .checkIn(code, receiptImageUrls: receipts, shelfCode: shelf),
    [DataArea.consignments, DataArea.warehouse],
  );

  Future<Consignment?> submitInspection(String id, InspectionDraft draft) =>
      _run(
        () => ref.read(staffRepositoryProvider).submitInspection(id, draft),
        [DataArea.consignments],
      );

  Future<WarehouseItem?> updateWarehouse(
    String id, {
    String? shelf,
    WarehouseStatus? status,
  }) => _run(
    () => ref
        .read(staffRepositoryProvider)
        .updateWarehouse(id, shelfCode: shelf, status: status),
    [DataArea.warehouse],
  );

  Future<bool> auctionDeliveryFailed(
    String id,
    String reason,
    DeliveryFaultKind fault,
  ) async =>
      await _run(
        () => ref
            .read(staffRepositoryProvider)
            .auctionDeliveryFailed(id, reason, fault)
            .then((_) => true),
        [DataArea.orders, DataArea.wallet],
      ) ??
      false;

  Future<bool> auctionReturnDecision(
    String id, {
    required bool accept,
    String? note,
  }) async =>
      await _run(
        () => ref
            .read(staffRepositoryProvider)
            .auctionReturnDecision(id, accept: accept, note: note)
            .then((_) => true),
        [DataArea.orders],
      ) ??
      false;

  Future<bool> auctionReturnReceived(String id) async =>
      await _run(
        () => ref
            .read(staffRepositoryProvider)
            .auctionReturnReceived(id)
            .then((_) => true),
        [DataArea.orders, DataArea.wallet],
      ) ??
      false;

  Future<WarehouseIncident?> reportIncident(
    String itemId,
    IncidentType type,
    String description,
  ) => _run(
    () => ref
        .read(staffRepositoryProvider)
        .reportIncident(itemId, type, description),
    [DataArea.warehouse],
  );

  Future<WarehouseIncident?> approveIncident(
    String id, {
    int sellerPercent = 100,
  }) => _run(
    () => ref
        .read(staffRepositoryProvider)
        .approveIncident(id, sellerPercent: sellerPercent),
    [DataArea.warehouse, DataArea.wallet],
  );

  Future<WarehouseIncident?> rejectIncident(String id, String reason) => _run(
    () => ref.read(staffRepositoryProvider).rejectIncident(id, reason),
    [DataArea.warehouse],
  );

  Future<void> reinspect(
    String lotId, {
    required bool passed,
    required String report,
  }) => _run(
    () => ref
        .read(staffRepositoryProvider)
        .reinspect(lotId, passed: passed, report: report),
    [DataArea.warehouse, DataArea.auctions],
  );

  Future<Order?> advanceOrder(String id, {String? tracking}) => _run(
    () => ref
        .read(staffRepositoryProvider)
        .advanceOrder(id, trackingCode: tracking),
    [DataArea.orders],
  );

  Future<bool> carrierDelivered(String id) async =>
      await _run(
        () => ref
            .read(staffRepositoryProvider)
            .carrierDelivered(id)
            .then((_) => true),
        [DataArea.orders, DataArea.wallet],
      ) ??
      false;

  Future<bool> carrierFailed(
    String id,
    String reason,
    DeliveryFaultKind fault,
  ) async =>
      await _run(
        () => ref
            .read(staffRepositoryProvider)
            .carrierFailed(id, reason, fault)
            .then((_) => true),
        [DataArea.orders, DataArea.wallet],
      ) ??
      false;
}
