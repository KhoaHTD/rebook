// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auction_dto.dart';
import '../models/place_bid_request.dart';

part 'auctions_client.g.dart';

@RestApi()
abstract class AuctionsClient {
  factory AuctionsClient(Dio dio, {String? baseUrl}) = _AuctionsClient;

  @GET('/auctions')
  Future<List<AuctionDto>> listAuctions();

  @GET('/auctions/{id}')
  Future<AuctionDto> getAuction({@Path('id') required String id});

  @POST('/auctions/{id}/bids')
  Future<AuctionDto> placeBid({
    @Path('id') required String id,
    @Body() required PlaceBidRequest body,
  });
}
