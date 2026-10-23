// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/decision_request.dart';
import '../models/order_detail.dart';
import '../models/order_status.dart';
import '../models/page_response_order_summary.dart';
import '../models/page_response_return_response.dart';
import '../models/reason_request.dart';
import '../models/ship_request.dart';

part 'order_management_client.g.dart';

@RestApi()
abstract class OrderManagementClient {
  factory OrderManagementClient(Dio dio, {String? baseUrl}) =
      _OrderManagementClient;

  /// [Staff] Xuất kho, giao cho shipper
  @POST('/staff/orders/{id}/ship')
  Future<OrderDetail> postStaffOrdersIdShip({
    @Path('id') required int id,
    @Body() ShipRequest? body,
  });

  /// [Staff] Xử lý trả hàng lô đấu giá (sàn chịu trách nhiệm)
  @POST('/staff/orders/{id}/return-decision')
  Future<OrderDetail> postStaffOrdersIdReturnDecision({
    @Path('id') required int id,
    @Body() required DecisionRequest body,
  });

  @POST('/staff/orders/{id}/delivery-failed')
  Future<OrderDetail> postStaffOrdersIdDeliveryFailed({
    @Path('id') required int id,
    @Body() required ReasonRequest body,
  });

  /// [Staff] Giao thành công / bàn giao tại kho
  @POST('/staff/orders/{id}/delivered')
  Future<OrderDetail> postStaffOrdersIdDelivered({@Path('id') required int id});

  @POST('/staff/orders/{id}/confirm')
  Future<OrderDetail> postStaffOrdersIdConfirm({@Path('id') required int id});

  /// Đã giao cho shipper (nhập mã vận đơn, bỏ trống để tự sinh)
  @POST('/seller/orders/{id}/ship')
  Future<OrderDetail> postSellerOrdersIdShip({
    @Path('id') required int id,
    @Body() ShipRequest? body,
  });

  /// Đồng ý / từ chối trả hàng (từ chối → Admin phân xử)
  @POST('/seller/orders/{id}/return-decision')
  Future<OrderDetail> postSellerOrdersIdReturnDecision({
    @Path('id') required int id,
    @Body() required DecisionRequest body,
  });

  /// [Giả lập] Giao thất bại
  @POST('/seller/orders/{id}/delivery-failed')
  Future<OrderDetail> postSellerOrdersIdDeliveryFailed({
    @Path('id') required int id,
    @Body() required ReasonRequest body,
  });

  /// [Giả lập] Đã giao thành công
  @POST('/seller/orders/{id}/delivered')
  Future<OrderDetail> postSellerOrdersIdDelivered({
    @Path('id') required int id,
  });

  /// Xác nhận đơn (trong 24h)
  @POST('/seller/orders/{id}/confirm')
  Future<OrderDetail> postSellerOrdersIdConfirm({@Path('id') required int id});

  @POST('/seller/orders/{id}/cancel')
  Future<OrderDetail> postSellerOrdersIdCancel({
    @Path('id') required int id,
    @Body() required ReasonRequest body,
  });

  /// Đồng ý / từ chối yêu cầu huỷ của người mua
  @POST('/seller/orders/{id}/cancel-request')
  Future<OrderDetail> postSellerOrdersIdCancelRequest({
    @Path('id') required int id,
    @Body() required DecisionRequest body,
  });

  /// [Admin] Phân xử: approve=true hoàn tiền người mua, false giữ đơn hoàn tất
  @POST('/admin/disputes/{orderId}/resolve')
  Future<OrderDetail> postAdminDisputesOrderIdResolve({
    @Path('orderId') required int orderId,
    @Body() required DecisionRequest body,
  });

  /// [Staff] Đơn lô đấu giá cần xuất kho / giao
  @GET('/staff/orders')
  Future<PageResponseOrderSummary> getStaffOrders({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') OrderStatus? status,
  });

  @GET('/seller/orders')
  Future<PageResponseOrderSummary> getSellerOrders({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') OrderStatus? status,
  });

  /// [Admin] Khiếu nại trả hàng chờ phân xử
  @GET('/admin/disputes')
  Future<PageResponseReturnResponse> getAdminDisputes({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });
}
