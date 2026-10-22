// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/config_request.dart';
import '../models/dashboard_response.dart';
import '../models/lock_request.dart';
import '../models/page_response_user_response.dart';
import '../models/page_response_withdraw_response.dart';
import '../models/process_request.dart';
import '../models/role.dart';
import '../models/role_request.dart';
import '../models/shop_response.dart';
import '../models/system_config.dart';
import '../models/trusted_request.dart';
import '../models/user_response.dart';
import '../models/user_status.dart';
import '../models/wallet_response.dart';
import '../models/withdraw_response.dart';

part 'admin_client.g.dart';

@RestApi()
abstract class AdminClient {
  factory AdminClient(Dio dio, {String? baseUrl}) = _AdminClient;

  /// Đổi role (USER / STAFF / ADMIN)
  @PUT('/admin/users/{id}/role')
  Future<UserResponse> putAdminUsersIdRole({
    @Path('id') required int id,
    @Body() required RoleRequest body,
  });

  /// Đánh dấu shop uy tín (tin đăng được tự duyệt)
  @PUT('/admin/shops/{id}/trusted')
  Future<ShopResponse> putAdminShopsIdTrusted({
    @Path('id') required int id,
    @Body() required TrustedRequest body,
  });

  @PUT('/admin/configs/{key}')
  Future<SystemConfig> putAdminConfigsKey({
    @Path('key') required String key,
    @Body() required ConfigRequest body,
  });

  /// Duyệt rút tiền (giả lập đã chuyển khoản) hoặc từ chối
  @POST('/admin/withdrawals/{id}')
  Future<WithdrawResponse> postAdminWithdrawalsId({
    @Path('id') required int id,
    @Body() required ProcessRequest body,
  });

  @POST('/admin/users/{id}/unlock')
  Future<UserResponse> postAdminUsersIdUnlock({@Path('id') required int id});

  /// Khoá tài khoản vi phạm
  @POST('/admin/users/{id}/lock')
  Future<UserResponse> postAdminUsersIdLock({
    @Path('id') required int id,
    @Body() required LockRequest body,
  });

  @POST('/admin/users/{id}/lift-auction-ban')
  Future<UserResponse> postAdminUsersIdLiftAuctionBan({
    @Path('id') required int id,
  });

  @GET('/admin/withdrawals')
  Future<PageResponseWithdrawResponse> getAdminWithdrawals({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });

  @GET('/admin/users')
  Future<PageResponseUserResponse> getAdminUsers({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('q') String? q,
    @Query('role') Role? role,
    @Query('status') UserStatus? status,
  });

  /// Số dư ví sàn (phí đã thu)
  @GET('/admin/platform-wallet')
  Future<WalletResponse> getAdminPlatformWallet();

  /// Dashboard: doanh thu, số đơn, tỷ lệ lô bán được
  @GET('/admin/dashboard')
  Future<DashboardResponse> getAdminDashboard();

  /// Cấu hình phí sàn, hoa hồng, bước giá, thời hạn
  @GET('/admin/configs')
  Future<List<SystemConfig>> getAdminConfigs();
}
