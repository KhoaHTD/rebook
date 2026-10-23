// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/add_deposit_request.dart';
import '../models/assign_lots_request.dart';
import '../models/bid_request.dart';
import '../models/bid_response.dart';
import '../models/delivery_option_request.dart';
import '../models/lot_detail.dart';
import '../models/lot_public.dart';
import '../models/lot_result.dart';
import '../models/order_detail.dart';
import '../models/page_response_lot_public.dart';
import '../models/page_response_session_summary.dart';
import '../models/proxy_bid_request.dart';
import '../models/reason_request.dart';
import '../models/registration_response.dart';
import '../models/session_detail.dart';
import '../models/session_register_request.dart';
import '../models/session_request.dart';
import '../models/session_state.dart';
import '../models/session_status.dart';
import '../models/session_summary.dart';

part 'auction_client.g.dart';

@RestApi()
abstract class AuctionClient {
  factory AuctionClient(Dio dio, {String? baseUrl}) = _AuctionClient;

  /// Đặt giá tối đa tự động (proxy bid) — đặt trước khi lô mở cũng được
  @PUT('/lots/{id}/proxy-bid')
  Future<Map<String, num>> putLotsIdProxyBid({
    @Path('id') required int id,
    @Body() required ProxyBidRequest body,
  });

  @DELETE('/lots/{id}/proxy-bid')
  Future<void> deleteLotsIdProxyBid({@Path('id') required int id});

  @GET('/admin/sessions/{id}')
  Future<SessionDetail> getAdminSessionsId({@Path('id') required int id});

  @PUT('/admin/sessions/{id}')
  Future<SessionSummary> putAdminSessionsId({
    @Path('id') required int id,
    @Body() required SessionRequest body,
  });

  /// [Admin] Xếp lô vào phiên theo thứ tự chạy
  @PUT('/admin/sessions/{id}/lots')
  Future<SessionDetail> putAdminSessionsIdLots({
    @Path('id') required int id,
    @Body() required AssignLotsRequest body,
  });

  /// [Staff] Tiếp tục phiên
  @POST('/staff/sessions/{id}/resume')
  Future<SessionSummary> postStaffSessionsIdResume({
    @Path('id') required int id,
  });

  /// [Staff] Tạm dừng phiên
  @POST('/staff/sessions/{id}/pause')
  Future<SessionSummary> postStaffSessionsIdPause({
    @Path('id') required int id,
  });

  /// [Staff] Huỷ một lô khi có sự cố
  @POST('/staff/lots/{id}/cancel')
  Future<dynamic> postStaffLotsIdCancel({
    @Path('id') required int id,
    @Body() required ReasonRequest body,
  });

  /// Đăng ký tham gia + đặt cọc (khoá tiền trong ví), nhận số bài
  @POST('/sessions/{id}/register')
  Future<RegistrationResponse> postSessionsIdRegister({
    @Path('id') required int id,
    @Body() required SessionRegisterRequest body,
  });

  /// Cọc thêm để nâng hạn mức trả giá
  @POST('/sessions/{id}/deposit')
  Future<RegistrationResponse> postSessionsIdDeposit({
    @Path('id') required int id,
    @Body() required AddDepositRequest body,
  });

  /// Hoá đơn lô thắng: giao tận nơi hoặc nhận tại kho
  @POST('/orders/{id}/delivery-option')
  Future<OrderDetail> postOrdersIdDeliveryOption({
    @Path('id') required int id,
    @Body() required DeliveryOptionRequest body,
  });

  /// Từ chối lời mời mua lần hai (second chance offer)
  @POST('/orders/{id}/decline-second-chance')
  Future<void> postOrdersIdDeclineSecondChance({@Path('id') required int id});

  /// Theo dõi lô (nhận nhắc trước phiên)
  @POST('/lots/{id}/watch')
  Future<Map<String, bool>> postLotsIdWatch({@Path('id') required int id});

  @DELETE('/lots/{id}/watch')
  Future<Map<String, bool>> deleteLotsIdWatch({@Path('id') required int id});

  /// Trả giá. 409 PRICE_CHANGED nếu người khác vừa trả trước
  @POST('/lots/{id}/bids')
  Future<BidResponse> postLotsIdBids({
    @Path('id') required int id,
    @Body() required BidRequest body,
  });

  @GET('/admin/sessions')
  Future<PageResponseSessionSummary> getAdminSessions({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });

  @POST('/admin/sessions')
  Future<SessionSummary> postAdminSessions({
    @Body() required SessionRequest body,
  });

  /// [Admin] Mở phiên ngay (demo) — phiên tự mở đúng giờ nên bình thường không cần
  @POST('/admin/sessions/{id}/start')
  Future<SessionSummary> postAdminSessionsIdStart({
    @Path('id') required int id,
  });

  /// [Admin] Công bố catalogue, mở đăng ký
  @POST('/admin/sessions/{id}/publish')
  Future<SessionSummary> postAdminSessionsIdPublish({
    @Path('id') required int id,
  });

  @POST('/admin/sessions/{id}/cancel')
  Future<SessionSummary> postAdminSessionsIdCancel({
    @Path('id') required int id,
    @Body() required ReasonRequest body,
  });

  /// Lịch phiên đấu giá
  @GET('/sessions')
  Future<PageResponseSessionSummary> getSessions({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') SessionStatus? status,
  });

  /// Catalogue phiên: danh sách lô, ảnh, giá ước tính
  @GET('/sessions/{id}')
  Future<SessionDetail> getSessionsId({@Path('id') required int id});

  /// Ảnh chụp trạng thái phòng đấu giá (gọi khi vào phòng / kết nối lại WebSocket).
  ///
  /// Sau đó nghe ws://<host>/ws/sessions/{id} để nhận LOT_OPENED, BID_PLACED, LOT_CLOSED, SESSION_*.
  @GET('/sessions/{id}/state')
  Future<SessionState> getSessionsIdState({@Path('id') required int id});

  /// Bảng kết quả phiên (số bài + giá)
  @GET('/sessions/{id}/results')
  Future<List<LotResult>> getSessionsIdResults({@Path('id') required int id});

  @GET('/me/watching')
  Future<List<LotPublic>> getMeWatching();

  @GET('/me/registrations')
  Future<List<RegistrationResponse>> getMeRegistrations();

  /// Chi tiết lô + báo cáo tình trạng
  @GET('/lots/{id}')
  Future<LotDetail> getLotsId({@Path('id') required int id});

  /// [Admin] Lô chờ xếp phiên
  @GET('/admin/lots/ready')
  Future<PageResponseLotPublic> getAdminLotsReady({
    @Query('page') int? page = 0,
    @Query('size') int? size = 50,
  });
}
