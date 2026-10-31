// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/add_cart_item_request.dart';
import '../models/cart_dto.dart';
import '../models/quantity_request.dart';

part 'cart_client.g.dart';

@RestApi()
abstract class CartClient {
  factory CartClient(Dio dio, {String? baseUrl}) = _CartClient;

  /// [addressId] - Địa chỉ để tính phí ship.
  ///
  /// [itemIds] - Chỉ tính các món giỏ đã chọn (mặc định cả giỏ). Phí ship tính lại theo khối lượng các món này.
  @GET('/cart')
  Future<CartDto> getCart({
    @Query('addressId') String? addressId,
    @Query('itemIds') List<String>? itemIds,
  });

  @POST('/cart')
  Future<CartDto> addCartItem({@Body() required AddCartItemRequest body});

  @PUT('/cart/{id}')
  Future<CartDto> updateCartItem({
    @Path('id') required String id,
    @Body() required QuantityRequest body,
  });

  @DELETE('/cart/{id}')
  Future<CartDto> removeCartItem({@Path('id') required String id});
}
