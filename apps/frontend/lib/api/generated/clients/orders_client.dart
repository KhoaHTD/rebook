// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/checkout_request.dart';
import '../models/checkout_response.dart';
import '../models/order_dto.dart';
import '../models/order_page.dart';
import '../models/order_status.dart';
import '../models/order_type.dart';
import '../models/pay_order_request.dart';
import '../models/reason_request.dart';
import '../models/return_request_input.dart';
import '../models/review_request.dart';

part 'orders_client.g.dart';

@RestApi()
abstract class OrdersClient {
  factory OrdersClient(Dio dio, {String? baseUrl}) = _OrdersClient;

  /// Tách giỏ thành mỗi shop một đơn, giữ hàng (trừ tồn kho) ngay. Thanh toán online hết hạn sau 15 phút.
  @POST('/orders/checkout')
  Future<CheckoutResponse> checkout({@Body() required CheckoutRequest body});

  @GET('/orders')
  Future<OrderPage> listMyOrders({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') OrderStatus? status,
    @Query('type') OrderType? type,
  });

  @GET('/orders/{id}')
  Future<OrderDto> getOrder({@Path('id') required String id});

  /// Thanh toán đơn đang PENDING_PAYMENT (đơn thường hoặc hóa đơn lô thắng) bằng ví hoặc VNPay.
  @POST('/orders/{id}/pay')
  Future<CheckoutResponse> payOrder({
    @Path('id') required String id,
    @Body() required PayOrderRequest body,
  });

  /// Hủy ngay khi PENDING_PAYMENT/PENDING_CONFIRM; sau khi shop xác nhận thì tạo yêu cầu hủy.
  @POST('/orders/{id}/cancel')
  Future<OrderDto> cancelOrder({
    @Path('id') required String id,
    @Body() required ReasonRequest body,
  });

  @POST('/orders/{id}/confirm-received')
  Future<OrderDto> confirmReceived({@Path('id') required String id});

  @POST('/orders/{id}/return')
  Future<OrderDto> requestReturn({
    @Path('id') required String id,
    @Body() required ReturnRequestInput body,
  });

  @POST('/orders/{id}/review')
  Future<OrderDto> reviewOrder({
    @Path('id') required String id,
    @Body() required ReviewRequest body,
  });
}
