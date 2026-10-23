// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/add_cart_request.dart';
import '../models/cart_response.dart';
import '../models/checkout_preview.dart';
import '../models/checkout_preview_request.dart';
import '../models/checkout_request.dart';
import '../models/checkout_response.dart';
import '../models/order_detail.dart';
import '../models/order_status.dart';
import '../models/page_response_order_summary.dart';
import '../models/page_response_review_response.dart';
import '../models/pay_request.dart';
import '../models/pay_response.dart';
import '../models/reason_request.dart';
import '../models/return_create_request.dart';
import '../models/review_request.dart';
import '../models/review_response.dart';
import '../models/update_cart_request.dart';

part 'order_client.g.dart';

@RestApi()
abstract class OrderClient {
  factory OrderClient(Dio dio, {String? baseUrl}) = _OrderClient;

  @PUT('/cart/{listingId}')
  Future<CartResponse> putCartListingId({
    @Path('listingId') required int listingId,
    @Body() required UpdateCartRequest body,
  });

  @DELETE('/cart/{listingId}')
  Future<CartResponse> deleteCartListingId({
    @Path('listingId') required int listingId,
  });

  /// Đánh giá shop (1–5 sao, mỗi đơn một lần)
  @POST('/orders/{id}/review')
  Future<ReviewResponse> postOrdersIdReview({
    @Path('id') required int id,
    @Body() required ReviewRequest body,
  });

  /// Yêu cầu trả hàng (chỉ khi sách khác mô tả)
  @POST('/orders/{id}/return')
  Future<OrderDetail> postOrdersIdReturn({
    @Path('id') required int id,
    @Body() required ReturnCreateRequest body,
  });

  /// Thanh toán đơn đang chờ (cả hoá đơn lô đấu giá) bằng WALLET hoặc VNPAY
  @POST('/orders/{id}/pay')
  Future<PayResponse> postOrdersIdPay({
    @Path('id') required int id,
    @Body() required PayRequest body,
  });

  /// Xác nhận đã nhận hàng → hoàn tất, giải ngân cho người bán
  @POST('/orders/{id}/confirm-received')
  Future<OrderDetail> postOrdersIdConfirmReceived({
    @Path('id') required int id,
  });

  /// Huỷ đơn (chưa xác nhận) hoặc gửi yêu cầu huỷ (đã xác nhận)
  @POST('/orders/{id}/cancel')
  Future<OrderDetail> postOrdersIdCancel({
    @Path('id') required int id,
    @Body() required ReasonRequest body,
  });

  /// Đặt hàng: mỗi shop một đơn, giữ hàng ngay.
  ///
  /// COD → đơn vào thẳng PENDING_CONFIRM. WALLET → trừ ví ngay. VNPAY → trả về payment.paymentUrl, hạn 15 phút.
  @POST('/orders/checkout')
  Future<CheckoutResponse> postOrdersCheckout({
    @Body() required CheckoutRequest body,
  });

  /// Xem trước: tách đơn theo shop + phí ship
  @POST('/orders/checkout/preview')
  Future<CheckoutPreview> postOrdersCheckoutPreview({
    @Body() required CheckoutPreviewRequest body,
  });

  /// Giỏ hàng (gom theo shop)
  @GET('/cart')
  Future<CartResponse> getCart();

  @POST('/cart')
  Future<CartResponse> postCart({@Body() required AddCartRequest body});

  @DELETE('/cart')
  Future<void> deleteCart();

  /// Đánh giá của shop (công khai)
  @GET('/shops/{shopId}/reviews')
  Future<PageResponseReviewResponse> getShopsShopIdReviews({
    @Path('shopId') required int shopId,
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });

  @GET('/orders')
  Future<PageResponseOrderSummary> getOrders({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') OrderStatus? status,
  });

  /// Chi tiết đơn + lịch sử trạng thái
  @GET('/orders/{id}')
  Future<OrderDetail> getOrdersId({@Path('id') required int id});
}
