import 'package:book_marketplace/features/consignment/domain/consignment_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

class FakeConsignmentRepository implements ConsignmentRepository {
  FakeConsignmentRepository(this._store);

  final FakeStore _store;

  @override
  Future<List<Consignment>> mine() => fakeCall(_store.myConsignments);

  @override
  Future<Consignment> get(String id) => fakeCall(() => _store.consignment(id));

  @override
  Future<Consignment> create(BookDraft book, int expectedPrice, String story) =>
      fakeCall(
        () => _store.createConsignment(book, expectedPrice, story),
        ms: 500,
      );

  @override
  Future<List<AppointmentSlot>> slots(String id) =>
      fakeCall(_store.appointmentSlots);

  @override
  Future<Consignment> bookAppointment(String id, DateTime at) =>
      fakeCall(() => _store.bookAppointment(id, at));

  @override
  Future<Consignment> decide(
    String id,
    SellerDecision decision, {
    int? counterReserve,
  }) => fakeCall(
    () => _store.decide(id, decision, counterReserve: counterReserve),
  );

  @override
  Future<Consignment> afterUnsold(
    String id,
    UnsoldChoice choice, {
    int? newReserve,
    int? fixedPrice,
  }) => fakeCall(
    () => _store.chooseAfterUnsold(
      id,
      choice,
      newReserve: newReserve,
      fixedPrice: fixedPrice,
    ),
  );

  @override
  Future<List<Category>> categories() =>
      fakeCall(() => List.of(_store.categories));
}
