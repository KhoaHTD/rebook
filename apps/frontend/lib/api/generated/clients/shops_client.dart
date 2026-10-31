// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/review_page.dart';
import '../models/seller_stats_dto.dart';
import '../models/shop_dto.dart';
import '../models/shop_request.dart';

part 'shops_client.g.dart';

@RestApi()
abstract class ShopsClient {
  factory ShopsClient(Dio dio, {String? baseUrl}) = _ShopsClient;

  @GET('/me/shop')
  Future<ShopDto> getMyShop();

  @POST('/me/shop')
  Future<ShopDto> openShop({@Body() required ShopRequest body});

  @PUT('/me/shop')
  Future<ShopDto> updateMyShop({@Body() required ShopRequest body});

  @GET('/me/shop/stats')
  Future<SellerStatsDto> getMyShopStats();

  @GET('/shops/{id}')
  Future<ShopDto> getShop({@Path('id') required String id});

  @GET('/shops/{id}/reviews')
  Future<ReviewPage> listShopReviews({
    @Path('id') required String id,
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });
}
