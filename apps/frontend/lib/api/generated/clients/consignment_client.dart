// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/appointment_request.dart';
import '../models/check_in_request.dart';
import '../models/consignment_create_request.dart';
import '../models/consignment_response.dart';
import '../models/consignment_status.dart';
import '../models/inspection_request.dart';
import '../models/page_response_consignment_response.dart';
import '../models/page_response_warehouse_response.dart';
import '../models/review_request.dart';
import '../models/seller_decision_request.dart';
import '../models/shelf_request.dart';
import '../models/unsold_decision_request.dart';
import '../models/warehouse_response.dart';
import '../models/warehouse_status.dart';

part 'consignment_client.g.dart';

@RestApi()
abstract class ConsignmentClient {
  factory ConsignmentClient(Dio dio, {String? baseUrl}) = _ConsignmentClient;

  /// [Staff] Cập nhật vị trí kệ
  @PUT('/staff/warehouse/{id}')
  Future<WarehouseResponse> putStaffWarehouseId({
    @Path('id') required int id,
    @Body() required ShelfRequest body,
  });

  /// [Staff] Xuất kho trả sách cho người bán (thu phí lưu kho nếu quá hạn)
  @POST('/staff/warehouse/{id}/return')
  Future<WarehouseResponse> postStaffWarehouseIdReturn({
    @Path('id') required int id,
  });

  /// [Staff] Sơ duyệt online
  @POST('/staff/consignments/{id}/review')
  Future<ConsignmentResponse> postStaffConsignmentsIdReview({
    @Path('id') required int id,
    @Body() required ReviewRequest body,
  });

  /// [Staff] Phiếu kiểm định + đề xuất giá
  @POST('/staff/consignments/{id}/inspection')
  Future<ConsignmentResponse> postStaffConsignmentsIdInspection({
    @Path('id') required int id,
    @Body() required InspectionRequest body,
  });

  /// [Staff] Nhận sách tại kho, tạo phiếu nhập kho
  @POST('/staff/consignments/{id}/check-in')
  Future<ConsignmentResponse> postStaffConsignmentsIdCheckIn({
    @Path('id') required int id,
    @Body() required CheckInRequest body,
  });

  @GET('/consignments')
  Future<List<ConsignmentResponse>> getConsignments();

  /// Gửi yêu cầu ký gửi đấu giá (giá mong muốn ≥ 300.000đ)
  @POST('/consignments')
  Future<ConsignmentResponse> postConsignments({
    @Body() required ConsignmentCreateRequest body,
  });

  @POST('/consignments/{id}/withdraw')
  Future<ConsignmentResponse> postConsignmentsIdWithdraw({
    @Path('id') required int id,
  });

  /// Lô không bán được: RELIST | CONVERT_TO_LISTING | RETURN
  @POST('/consignments/{id}/unsold-decision')
  Future<ConsignmentResponse> postConsignmentsIdUnsoldDecision({
    @Path('id') required int id,
    @Body() required UnsoldDecisionRequest body,
  });

  /// Chấp nhận / đề nghị giá sàn khác / rút sách sau kiểm định
  @POST('/consignments/{id}/decision')
  Future<ConsignmentResponse> postConsignmentsIdDecision({
    @Path('id') required int id,
    @Body() required SellerDecisionRequest body,
  });

  /// Đặt / đổi lịch hẹn mang sách tới kho
  @POST('/consignments/{id}/appointment')
  Future<ConsignmentResponse> postConsignmentsIdAppointment({
    @Path('id') required int id,
    @Body() required AppointmentRequest body,
  });

  /// [Staff] Sách trong kho
  @GET('/staff/warehouse')
  Future<PageResponseWarehouseResponse> getStaffWarehouse({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') WarehouseStatus? status,
  });

  /// [Staff] Danh sách yêu cầu ký gửi
  @GET('/staff/consignments')
  Future<PageResponseConsignmentResponse> getStaffConsignments({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') ConsignmentStatus? status,
  });

  /// [Staff] Lịch hẹn nhận sách (mặc định 7 ngày tới)
  @GET('/staff/appointments')
  Future<List<ConsignmentResponse>> getStaffAppointments({
    @Query('from') DateTime? from,
    @Query('to') DateTime? to,
  });

  /// [Staff] Tra lịch hẹn theo mã QR
  @GET('/staff/appointments/{code}')
  Future<ConsignmentResponse> getStaffAppointmentsCode({
    @Path('code') required String code,
  });

  /// Chi tiết ký gửi: kết quả kiểm định, lô, kho
  @GET('/consignments/{id}')
  Future<ConsignmentResponse> getConsignmentsId({@Path('id') required int id});
}
