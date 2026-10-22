import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/consignment/data/consignment_repository_provider.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

part 'consignment_providers.g.dart';

@riverpod
Future<List<Consignment>> myConsignments(Ref ref) {
  ref.watchArea(DataArea.consignments);
  return ref.watch(consignmentRepositoryProvider).mine();
}

@riverpod
Future<Consignment> consignmentDetail(Ref ref, String id) {
  ref
    ..watchArea(DataArea.consignments)
    ..watchArea(DataArea.auctions);
  return ref.watch(consignmentRepositoryProvider).get(id);
}

@riverpod
Future<List<AppointmentSlot>> appointmentSlots(Ref ref, String id) =>
    ref.watch(consignmentRepositoryProvider).slots(id);

@riverpod
Future<List<Category>> consignmentCategories(Ref ref) =>
    ref.watch(consignmentRepositoryProvider).categories();

@riverpod
class ConsignmentActions extends _$ConsignmentActions {
  @override
  FutureOr<void> build() {}

  Future<Consignment?> _run(Future<Consignment> Function() action) async {
    state = const AsyncLoading();
    Consignment? result;
    state = await AsyncValue.guard(() async {
      result = await action();
    });
    if (result != null) {
      ref.read(dataChangesProvider.notifier).bump(DataArea.consignments);
    }
    return result;
  }

  Future<Consignment?> create(BookDraft book, int expected, String story) =>
      _run(
        () => ref
            .read(consignmentRepositoryProvider)
            .create(book, expected, story),
      );

  Future<Consignment?> book(String id, DateTime at) => _run(
    () => ref.read(consignmentRepositoryProvider).bookAppointment(id, at),
  );

  Future<Consignment?> decide(
    String id,
    SellerDecision decision, {
    int? counterReserve,
  }) => _run(
    () => ref
        .read(consignmentRepositoryProvider)
        .decide(id, decision, counterReserve: counterReserve),
  );

  Future<Consignment?> afterUnsold(
    String id,
    UnsoldChoice choice, {
    int? newReserve,
    int? fixedPrice,
  }) => _run(
    () => ref
        .read(consignmentRepositoryProvider)
        .afterUnsold(
          id,
          choice,
          newReserve: newReserve,
          fixedPrice: fixedPrice,
        ),
  );
}
