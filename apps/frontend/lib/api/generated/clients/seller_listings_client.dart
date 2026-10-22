// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/listing_dto.dart';
import '../models/listing_page.dart';
import '../models/listing_request.dart';
import '../models/listing_status.dart';
import '../models/visibility_request.dart';

part 'seller_listings_client.g.dart';

@RestApi()
abstract class SellerListingsClient {
  factory SellerListingsClient(Dio dio, {String? baseUrl}) =
      _SellerListingsClient;

  @GET('/seller/listings')
  Future<ListingPage> listMyListings({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
    @Query('status') ListingStatus? status,
  });

  @POST('/seller/listings')
  Future<ListingDto> createListing({@Body() required ListingRequest body});

  @PUT('/seller/listings/{id}')
  Future<ListingDto> updateListing({
    @Path('id') required String id,
    @Body() required ListingRequest body,
  });

  @DELETE('/seller/listings/{id}')
  Future<void> deleteListing({@Path('id') required String id});

  @POST('/seller/listings/{id}/visibility')
  Future<ListingDto> setListingVisibility({
    @Path('id') required String id,
    @Body() required VisibilityRequest body,
  });
}
