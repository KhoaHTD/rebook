import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

/// Ký gửi đấu giá phía người gửi (SRS 6.1, 6.2, 6.6).
abstract interface class ConsignmentRepository {
  Future<List<Consignment>> mine();

  Future<Consignment> get(String id);

  Future<Consignment> create(BookDraft book, int expectedPrice, String story);

  Future<List<AppointmentSlot>> slots(String id);

  Future<Consignment> bookAppointment(String id, DateTime at);

  /// Sau kiểm định: chấp nhận / đề nghị giá sàn / rút.
  Future<Consignment> decide(
    String id,
    SellerDecision decision, {
    int? counterReserve,
  });

  /// Lô không bán được: phiên sau / bán giá cố định / nhận lại.
  Future<Consignment> afterUnsold(
    String id,
    UnsoldChoice choice, {
    int? newReserve,
    int? fixedPrice,
  });

  Future<List<Category>> categories();
}
