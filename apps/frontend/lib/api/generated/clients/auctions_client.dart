// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auction_session_dto.dart';
import '../models/bid_dto.dart';
import '../models/lot_dto.dart';
import '../models/order_dto.dart';
import '../models/place_bid_request.dart';
import '../models/proxy_bid_dto.dart';
import '../models/proxy_bid_request.dart';
import '../models/register_session_request.dart';
import '../models/registration_dto.dart';
import '../models/second_chance_offer_dto.dart';
import '../models/session_catalogue_dto.dart';
import '../models/session_result_dto.dart';
import '../models/session_state_dto.dart';
import '../models/session_status.dart';
import '../models/watch_request.dart';

part 'auctions_client.g.dart';

@RestApi()
abstract class AuctionsClient {
  factory AuctionsClient(Dio dio, {String? baseUrl}) = _AuctionsClient;

  @GET('/sessions')
  Future<List<AuctionSessionDto>> listSessions({
    @Query('status') SessionStatus? status,
  });

  @GET('/sessions/{id}')
  Future<SessionCatalogueDto> getSessionCatalogue({
    @Path('id') required String id,
  });

  /// Đồng ý quy chế, khóa cọc trong ví (DEPOSIT_HOLD), cấp số bài. Hạn mức = cọc × 10.
  @POST('/sessions/{id}/register')
  Future<RegistrationDto> registerSession({
    @Path('id') required String id,
    @Body() required RegisterSessionRequest body,
  });

  @GET('/sessions/{id}/registration')
  Future<RegistrationDto> getMyRegistration({@Path('id') required String id});

  /// Ảnh chụp trạng thái phiên — gọi khi vào phòng hoặc reconnect, rồi mới nghe /topic/sessions/{id}.
  @GET('/sessions/{id}/state')
  Future<SessionStateDto> getSessionState({@Path('id') required String id});

  @GET('/sessions/{id}/results')
  Future<SessionResultDto> getSessionResults({@Path('id') required String id});

  @GET('/lots/{id}')
  Future<LotDto> getLot({@Path('id') required String id});

  @GET('/lots/{id}/bids')
  Future<List<BidDto>> listLotBids({@Path('id') required String id});

  /// Cũng có thể gửi qua STOMP /app/lots/{lotId}/bid. Lỗi 409 "Giá đã thay đổi" nếu người khác trả trước.
  @POST('/lots/{id}/bids')
  Future<BidDto> placeBid({
    @Path('id') required String id,
    @Body() required PlaceBidRequest body,
  });

  @PUT('/lots/{id}/proxy-bid')
  Future<ProxyBidDto> setProxyBid({
    @Path('id') required String id,
    @Body() required ProxyBidRequest body,
  });

  @POST('/lots/{id}/watch')
  Future<LotDto> watchLot({
    @Path('id') required String id,
    @Body() required WatchRequest body,
  });

  /// Lời mời mua lần hai (SRS 6.6) gửi tới người trả giá cao thứ hai khi người thắng bỏ thanh toán. Chỉ mời khi giá của họ ≥ giá sàn.
  @GET('/me/offers')
  Future<List<SecondChanceOfferDto>> listSecondChanceOffers();

  /// Nhận mua với giá đã trả; trả về hoá đơn lô (đơn AUCTION).
  @POST('/me/offers/{id}/accept')
  Future<OrderDto> acceptSecondChanceOffer({@Path('id') required String id});

  @POST('/me/offers/{id}/decline')
  Future<SecondChanceOfferDto> declineSecondChanceOffer({
    @Path('id') required String id,
  });

  /// Các phiên đấu giá tôi theo dõi (phiên yêu thích).
  @GET('/me/watched-sessions')
  Future<List<AuctionSessionDto>> listWatchedSessions();

  /// Theo dõi / bỏ theo dõi cả phiên (khác với theo dõi từng lô).
  @POST('/sessions/{id}/watch')
  Future<AuctionSessionDto> watchSession({
    @Path('id') required String id,
    @Body() required WatchRequest body,
  });

  @GET('/me/registrations')
  Future<List<RegistrationDto>> listMyRegistrations();
}
