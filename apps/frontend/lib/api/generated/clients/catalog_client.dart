// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/category_request.dart';
import '../models/category_response.dart';
import '../models/condition_grade.dart';
import '../models/listing_detail.dart';
import '../models/listing_request.dart';
import '../models/listing_status.dart';
import '../models/page_response_listing_summary.dart';
import '../models/reject_request.dart';
import '../models/stock_request.dart';

part 'catalog_client.g.dart';

@RestApi()
abstract class CatalogClient {
  factory CatalogClient(Dio dio, {String? baseUrl}) = _CatalogClient;

  @PUT('/seller/listings/{id}')
  Future<ListingDetail> putSellerListingsId({
    @Path('id') required int id,
    @Body() required ListingRequest body,
  });

  /// Ẩn tin đăng
  @DELETE('/seller/listings/{id}')
  Future<ListingDetail> deleteSellerListingsId({@Path('id') required int id});

  /// Cập nhật tồn kho
  @PUT('/seller/listings/{id}/stock')
  Future<ListingDetail> putSellerListingsIdStock({
    @Path('id') required int id,
    @Body() required StockRequest body,
  });

  @PUT('/admin/categories/{id}')
  Future<CategoryResponse> putAdminCategoriesId({
    @Path('id') required int id,
    @Body() required CategoryRequest body,
  });

  @DELETE('/admin/categories/{id}')
  Future<void> deleteAdminCategoriesId({@Path('id') required int id});

  /// Tin đăng của shop tôi
  @GET('/seller/listings')
  Future<PageResponseListingSummary> getSellerListings({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') ListingStatus? status,
  });

  /// Đăng bán sách giá cố định (tối thiểu 3 ảnh)
  @POST('/seller/listings')
  Future<ListingDetail> postSellerListings({
    @Body() required ListingRequest body,
  });

  /// Hiện lại tin đã ẩn
  @POST('/seller/listings/{id}/show')
  Future<ListingDetail> postSellerListingsIdShow({@Path('id') required int id});

  @POST('/admin/listings/{id}/reject')
  Future<ListingDetail> postAdminListingsIdReject({
    @Path('id') required int id,
    @Body() required RejectRequest body,
  });

  @POST('/admin/listings/{id}/approve')
  Future<ListingDetail> postAdminListingsIdApprove({
    @Path('id') required int id,
  });

  @POST('/admin/categories')
  Future<CategoryResponse> postAdminCategories({
    @Body() required CategoryRequest body,
  });

  /// Tìm kiếm / lọc sách đang bán.
  ///
  /// sort: newest | price_asc | price_desc | best_selling. category lọc cả danh mục con.
  @GET('/listings')
  Future<PageResponseListingSummary> getListings({
    @Query('sort') String? sort = 'newest',
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('q') String? q,
    @Query('category') int? category,
    @Query('author') String? author,
    @Query('condition') ConditionGrade? condition,
    @Query('minPrice') num? minPrice,
    @Query('maxPrice') num? maxPrice,
    @Query('shopId') int? shopId,
  });

  /// Chi tiết sách đang bán
  @GET('/listings/{id}')
  Future<ListingDetail> getListingsId({@Path('id') required int id});

  /// Cây danh mục thể loại
  @GET('/categories')
  Future<List<CategoryResponse>> getCategories();

  /// [Admin] Chi tiết tin (mọi trạng thái)
  @GET('/admin/listings/{id}')
  Future<ListingDetail> getAdminListingsId({@Path('id') required int id});

  /// [Admin] Tin chờ duyệt
  @GET('/admin/listings/pending')
  Future<PageResponseListingSummary> getAdminListingsPending({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });
}
