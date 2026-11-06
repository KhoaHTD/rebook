// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/cod_remit_request.dart';
import '../models/order_detail.dart';
import '../models/page_response_cod_pending_response.dart';

part 'cod_client.g.dart';

@RestApi()
abstract class CodClient {
  factory CodClient(Dio dio, {String? baseUrl}) = _CodClient;

  /// [Admin] Xác nhận sàn đã nhận đúng số tiền COD của đơn (rồi mới trả shop / hoàn người mua)
  @POST('/admin/cod/{orderId}/remit')
  Future<OrderDetail> postAdminCodOrderIdRemit({
    @Path('orderId') required int orderId,
    @Body() required CodRemitRequest body,
  });

  /// [Admin] Đơn COD đã giao nhưng sàn chưa nhận tiền đối soát
  @GET('/admin/cod/pending')
  Future<PageResponseCodPendingResponse> getAdminCodPending({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });
}
