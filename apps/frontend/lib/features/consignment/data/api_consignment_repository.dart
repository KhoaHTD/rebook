import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/consignment/domain/consignment_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

class ApiConsignmentRepository implements ConsignmentRepository {
  ApiConsignmentRepository(this._client);

  final api.RestClient _client;

  @override
  Future<List<Consignment>> mine() => guardApi(
    () async => (await _client.consignments.listMyConsignments())
        .map((e) => e.toDomain())
        .toList(),
  );

  @override
  Future<Consignment> get(String id) => guardApi(
    () async => (await _client.consignments.getConsignment(id: id)).toDomain(),
  );

  @override
  Future<Consignment> create(BookDraft book, int expectedPrice, String story) =>
      guardApi(
        () async => (await _client.consignments.createConsignment(
          body: api.ConsignmentRequest(
            book: book.toRequest(),
            expectedPrice: expectedPrice,
            story: story,
          ),
        )).toDomain(),
      );

  @override
  Future<List<AppointmentSlot>> slots(String id) => guardApi(
    () async => [
      for (final s in await _client.consignments.listAppointmentSlots(id: id))
        AppointmentSlot(startAt: s.startAt, available: s.available),
    ],
  );

  @override
  Future<Consignment> bookAppointment(String id, DateTime at) => guardApi(
    () async => (await _client.consignments.bookAppointment(
      id: id,
      body: api.AppointmentRequest(startAt: at),
    )).toDomain(),
  );

  @override
  Future<Consignment> decide(
    String id,
    SellerDecision decision, {
    int? counterReserve,
  }) => guardApi(
    () async => (await _client.consignments.decideConsignment(
      id: id,
      body: api.ConsignmentDecisionRequest(
        decision: toApiEnum(api.SellerDecision.values, decision),
        counterReserve: counterReserve,
        agreeTerms: decision != SellerDecision.withdraw,
      ),
    )).toDomain(),
  );

  @override
  Future<Consignment> afterUnsold(
    String id,
    UnsoldChoice choice, {
    int? newReserve,
    int? fixedPrice,
  }) => guardApi(
    () async => (await _client.consignments.chooseAfterUnsold(
      id: id,
      body: api.UnsoldChoiceRequest(
        choice: toApiEnum(api.UnsoldChoice.values, choice),
        newReserve: newReserve,
        fixedPrice: fixedPrice,
      ),
    )).toDomain(),
  );

  @override
  Future<List<Category>> categories() => guardApi(
    () async => (await _client.categories.listCategories())
        .map((e) => e.toDomain())
        .toList(),
  );
}
