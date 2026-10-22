// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/address_request.dart';
import '../models/address_response.dart';
import '../models/change_password_request.dart';
import '../models/shop_request.dart';
import '../models/shop_response.dart';
import '../models/update_profile_request.dart';
import '../models/user_response.dart';

part 'user_client.g.dart';

@RestApi()
abstract class UserClient {
  factory UserClient(Dio dio, {String? baseUrl}) = _UserClient;

  /// Hồ sơ của tôi
  @GET('/me')
  Future<UserResponse> getMe();

  @PUT('/me')
  Future<UserResponse> putMe({@Body() required UpdateProfileRequest body});

  /// Shop của tôi (kèm thông tin nhận tiền)
  @GET('/me/shop')
  Future<ShopResponse> getMeShop();

  /// Bật shop / cập nhật thông tin shop
  @PUT('/me/shop')
  Future<ShopResponse> putMeShop({@Body() required ShopRequest body});

  @PUT('/me/addresses/{id}')
  Future<AddressResponse> putMeAddressesId({
    @Path('id') required int id,
    @Body() required AddressRequest body,
  });

  @DELETE('/me/addresses/{id}')
  Future<void> deleteMeAddressesId({@Path('id') required int id});

  @POST('/me/password')
  Future<void> postMePassword({@Body() required ChangePasswordRequest body});

  /// Sổ địa chỉ
  @GET('/me/addresses')
  Future<List<AddressResponse>> getMeAddresses();

  @POST('/me/addresses')
  Future<AddressResponse> postMeAddresses({
    @Body() required AddressRequest body,
  });

  /// Trang shop công khai
  @GET('/shops/{id}')
  Future<ShopResponse> getShopsId({@Path('id') required int id});
}
