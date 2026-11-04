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
    () async => [
      for (final c in await _client.consignment.getConsignments()) c.toDomain(),
    ],
  );

  @override
  Future<Consignment> get(String id) => guardApi(
    () async =>
        (await _client.consignment.getConsignmentsId(id: apiId(id))).toDomain(),
  );

  @override
  Future<Consignment> create(BookDraft book, int expectedPrice, String story) =>
      guardApi(
        () async => (await _client.consignment.postConsignments(
          body: api.ConsignmentCreateRequest(
            book: book.toRequest(),
            expectedPrice: expectedPrice,
            provenance: story,
          ),
        )).toDomain(),
      );

  /// Backend không có API "khung giờ trống": kho nhận sách 8:00–17:00, hẹn trong
  /// 7 ngày kể từ lúc duyệt — app tự sinh khung giờ chẵn trong khoảng đó.
  @override
  Future<List<AppointmentSlot>> slots(String id) async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day + 1);
    return [
      for (var d = 0; d < 6; d++)
        for (var h = 8; h <= 16; h++)
          AppointmentSlot(
            startAt: DateTime(first.year, first.month, first.day + d, h),
            available: true,
          ),
    ];
  }

  @override
  Future<Consignment> bookAppointment(String id, DateTime at) => guardApi(
    () async => (await _client.consignment.postConsignmentsIdAppointment(
      id: apiId(id),
      body: api.AppointmentRequest(appointmentAt: at.toUtc()),
    )).toDomain(),
  );

  /// `counter` = đồng ý nhưng đề xuất giá sàn khác (backend gộp vào cùng một lệnh accept).
  @override
  Future<Consignment> decide(
    String id,
    SellerDecision decision, {
    int? counterReserve,
  }) => guardApi(() async {
    final withdraw = decision == SellerDecision.withdraw;
    return (await _client.consignment.postConsignmentsIdDecision(
      id: apiId(id),
      body: api.SellerDecisionRequest(
        decision: withdraw
            ? api.SellerDecisionAction.withdraw
            : api.SellerDecisionAction.accept,
        counterReserve: decision == SellerDecision.counter
            ? counterReserve
            : null,
        agreeTerms: !withdraw,
      ),
    )).toDomain();
  });

  @override
  Future<Consignment> afterUnsold(
    String id,
    UnsoldChoice choice, {
    int? newReserve,
    int? fixedPrice,
  }) => guardApi(
    () async => (await _client.consignment.postConsignmentsIdUnsoldDecision(
      id: apiId(id),
      body: api.UnsoldDecisionRequest(
        action: unsoldActionToApi(choice),
        newReserve: newReserve,
        listingPrice: fixedPrice,
      ),
    )).toDomain(),
  );

  @override
  Future<List<Category>> categories() => guardApi(
    () async => flattenCategories(await _client.catalog.getCategories()),
  );
}
