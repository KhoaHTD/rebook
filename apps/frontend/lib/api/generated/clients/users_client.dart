// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/address_dto.dart';
import '../models/address_request.dart';
import '../models/register_device_request.dart';
import '../models/update_profile_request.dart';
import '../models/user_dto.dart';

part 'users_client.g.dart';

@RestApi()
abstract class UsersClient {
  factory UsersClient(Dio dio, {String? baseUrl}) = _UsersClient;

  @GET('/me')
  Future<UserDto> getMe();

  @PUT('/me')
  Future<UserDto> updateMe({@Body() required UpdateProfileRequest body});

  @GET('/me/addresses')
  Future<List<AddressDto>> listAddresses();

  @POST('/me/addresses')
  Future<AddressDto> createAddress({@Body() required AddressRequest body});

  @PUT('/me/addresses/{id}')
  Future<AddressDto> updateAddress({
    @Path('id') required String id,
    @Body() required AddressRequest body,
  });

  @DELETE('/me/addresses/{id}')
  Future<void> deleteAddress({@Path('id') required String id});

  @POST('/me/devices')
  Future<void> registerDevice({@Body() required RegisterDeviceRequest body});
}
