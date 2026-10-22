// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/approval_request.dart';
import '../models/auction_session_dto.dart';
import '../models/category_dto.dart';
import '../models/category_request.dart';
import '../models/dashboard_dto.dart';
import '../models/listing_dto.dart';
import '../models/listing_page.dart';
import '../models/listing_status.dart';
import '../models/lock_user_request.dart';
import '../models/lot_dto.dart';
import '../models/lot_status.dart';
import '../models/order_dto.dart';
import '../models/reason_request.dart';
import '../models/return_decision_request.dart';
import '../models/session_catalogue_dto.dart';
import '../models/session_lots_request.dart';
import '../models/session_request.dart';
import '../models/system_config_dto.dart';
import '../models/user_dto.dart';
import '../models/user_page.dart';
import '../models/withdrawal_dto.dart';

part 'admin_client.g.dart';

@RestApi()
abstract class AdminClient {
  factory AdminClient(Dio dio, {String? baseUrl}) = _AdminClient;

  @GET('/admin/listings')
  Future<ListingPage> adminListListings({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') ListingStatus? status,
  });

  @POST('/admin/listings/{id}/review')
  Future<ListingDto> adminReviewListing({
    @Path('id') required String id,
    @Body() required ApprovalRequest body,
  });

  @GET('/admin/users')
  Future<UserPage> adminListUsers({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('q') String? q,
  });

  @POST('/admin/users/{id}/lock')
  Future<UserDto> adminLockUser({
    @Path('id') required String id,
    @Body() required LockUserRequest body,
  });

  @POST('/admin/categories')
  Future<CategoryDto> adminCreateCategory({
    @Body() required CategoryRequest body,
  });

  @PUT('/admin/categories/{id}')
  Future<CategoryDto> adminUpdateCategory({
    @Path('id') required String id,
    @Body() required CategoryRequest body,
  });

  @DELETE('/admin/categories/{id}')
  Future<void> adminDeleteCategory({@Path('id') required String id});

  @GET('/admin/sessions')
  Future<List<AuctionSessionDto>> adminListSessions();

  @POST('/admin/sessions')
  Future<AuctionSessionDto> adminCreateSession({
    @Body() required SessionRequest body,
  });

  @PUT('/admin/sessions/{id}')
  Future<AuctionSessionDto> adminUpdateSession({
    @Path('id') required String id,
    @Body() required SessionRequest body,
  });

  /// Thứ tự trong mảng = số thứ tự lô.
  @PUT('/admin/sessions/{id}/lots')
  Future<SessionCatalogueDto> adminSetSessionLots({
    @Path('id') required String id,
    @Body() required SessionLotsRequest body,
  });

  @POST('/admin/sessions/{id}/publish')
  Future<AuctionSessionDto> adminPublishSession({
    @Path('id') required String id,
  });

  @POST('/admin/sessions/{id}/pause')
  Future<AuctionSessionDto> adminPauseSession({@Path('id') required String id});

  @POST('/admin/sessions/{id}/resume')
  Future<AuctionSessionDto> adminResumeSession({
    @Path('id') required String id,
  });

  @GET('/admin/lots')
  Future<List<LotDto>> adminListLots({@Query('status') LotStatus? status});

  @POST('/admin/lots/{id}/cancel')
  Future<LotDto> adminCancelLot({
    @Path('id') required String id,
    @Body() required ReasonRequest body,
  });

  @GET('/admin/configs')
  Future<SystemConfigDto> adminGetConfig();

  @PUT('/admin/configs')
  Future<SystemConfigDto> adminUpdateConfig({
    @Body() required SystemConfigDto body,
  });

  @GET('/admin/withdrawals')
  Future<List<WithdrawalDto>> adminListWithdrawals();

  @POST('/admin/withdrawals/{id}/complete')
  Future<WithdrawalDto> adminCompleteWithdrawal({
    @Path('id') required String id,
  });

  /// Yêu cầu trả hàng bị shop từ chối, chờ Admin phân xử.
  @GET('/admin/returns')
  Future<List<OrderDto>> adminListDisputes();

  @POST('/admin/returns/{id}/resolve')
  Future<OrderDto> adminResolveDispute({
    @Path('id') required String id,
    @Body() required ReturnDecisionRequest body,
  });

  @GET('/admin/dashboard')
  Future<DashboardDto> adminDashboard();
}
