// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/condition_grade.dart';
import '../models/favorite_request.dart';
import '../models/home_feed_dto.dart';
import '../models/listing_dto.dart';
import '../models/listing_page.dart';
import '../models/listing_sort.dart';

part 'listings_client.g.dart';

@RestApi()
abstract class ListingsClient {
  factory ListingsClient(Dio dio, {String? baseUrl}) = _ListingsClient;

  @GET('/listings')
  Future<ListingPage> searchListings({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('q') String? q,
    @Query('categoryId') String? categoryId,
    @Query('author') String? author,
    @Query('condition') ConditionGrade? condition,
    @Query('minPrice') int? minPrice,
    @Query('maxPrice') int? maxPrice,
    @Query('shopId') String? shopId,
    @Query('sort') ListingSort? sort,
  });

  @GET('/listings/{id}')
  Future<ListingDto> getListing({@Path('id') required String id});

  /// Thêm / bỏ một tin bán khỏi danh sách yêu thích (SRS 3, mở rộng).
  @POST('/listings/{id}/favorite')
  Future<ListingDto> setFavoriteListing({
    @Path('id') required String id,
    @Body() required FavoriteRequest body,
  });

  @GET('/home/feed')
  Future<HomeFeedDto> getHomeFeed();

  /// Sách tôi đã thả tim, mới nhất trước.
  @GET('/me/favorites')
  Future<List<ListingDto>> listFavoriteListings();
}
