// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/order_dto.dart';
import '../models/order_page.dart';
import '../models/order_status.dart';
import '../models/reason_request.dart';
import '../models/return_decision_request.dart';
import '../models/ship_request.dart';

part 'seller_orders_client.g.dart';

@RestApi()
abstract class SellerOrdersClient {
  factory SellerOrdersClient(Dio dio, {String? baseUrl}) = _SellerOrdersClient;

  @GET('/seller/orders')
  Future<OrderPage> listShopOrders({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') OrderStatus? status,
  });

  @POST('/seller/orders/{id}/confirm')
  Future<OrderDto> confirmShopOrder({@Path('id') required String id});

  @POST('/seller/orders/{id}/ship')
  Future<OrderDto> shipShopOrder({
    @Path('id') required String id,
    @Body() required ShipRequest body,
  });

  /// Giả lập đơn vị vận chuyển báo giao thành công (đồ án).
  @POST('/seller/orders/{id}/delivered')
  Future<OrderDto> markShopOrderDelivered({@Path('id') required String id});

  @POST('/seller/orders/{id}/cancel')
  Future<OrderDto> cancelShopOrder({
    @Path('id') required String id,
    @Body() required ReasonRequest body,
  });

  @POST('/seller/orders/{id}/return-decision')
  Future<OrderDto> decideReturn({
    @Path('id') required String id,
    @Body() required ReturnDecisionRequest body,
  });
}
