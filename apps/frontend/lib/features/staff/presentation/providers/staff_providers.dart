import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/staff/data/staff_repository_provider.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

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
Future<List<Order>> staffAuctionOrders(Ref ref) {
  ref.watchArea(DataArea.orders);
  return ref.watch(staffRepositoryProvider).auctionOrders();
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

  Future<Order?> advanceOrder(String id, {String? tracking}) => _run(
    () => ref
        .read(staffRepositoryProvider)
        .advanceOrder(id, trackingCode: tracking),
    [DataArea.orders],
  );
}
