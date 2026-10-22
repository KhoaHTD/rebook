// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/approval_request.dart';
import '../models/check_in_request.dart';
import '../models/consignment_dto.dart';
import '../models/consignment_status.dart';
import '../models/inspection_request.dart';
import '../models/order_dto.dart';
import '../models/order_status.dart';
import '../models/ship_request.dart';
import '../models/warehouse_item_dto.dart';
import '../models/warehouse_status.dart';
import '../models/warehouse_update_request.dart';

part 'staff_client.g.dart';

@RestApi()
abstract class StaffClient {
  factory StaffClient(Dio dio, {String? baseUrl}) = _StaffClient;

  @GET('/staff/consignments')
  Future<List<ConsignmentDto>> staffListConsignments({
    @Query('status') ConsignmentStatus? status,
  });

  @POST('/staff/consignments/{id}/pre-review')
  Future<ConsignmentDto> staffPreReview({
    @Path('id') required String id,
    @Body() required ApprovalRequest body,
  });

  @GET('/staff/appointments')
  Future<List<ConsignmentDto>> staffListAppointments({
    @Query('date') DateTime? date,
  });

  /// Quét / nhập mã lịch hẹn, lập biên nhận ký gửi, gán mã kho.
  @POST('/staff/consignments/check-in')
  Future<ConsignmentDto> staffCheckIn({@Body() required CheckInRequest body});

  @POST('/staff/consignments/{id}/inspection')
  Future<ConsignmentDto> staffSubmitInspection({
    @Path('id') required String id,
    @Body() required InspectionRequest body,
  });

  @GET('/staff/warehouse')
  Future<List<WarehouseItemDto>> staffListWarehouse({
    @Query('status') WarehouseStatus? status,
  });

  @PUT('/staff/warehouse/{id}')
  Future<WarehouseItemDto> staffUpdateWarehouseItem({
    @Path('id') required String id,
    @Body() required WarehouseUpdateRequest body,
  });

  /// Đơn AUCTION cần kho đóng gói / giao.
  @GET('/staff/orders')
  Future<List<OrderDto>> staffListAuctionOrders({
    @Query('status') OrderStatus? status,
  });

  /// Kho chuyển đơn đấu giá sang bước kế (PREPARING → SHIPPING → DELIVERED).
  @POST('/staff/orders/{id}/advance')
  Future<OrderDto> staffAdvanceOrder({
    @Path('id') required String id,
    @Body() required ShipRequest body,
  });
}
