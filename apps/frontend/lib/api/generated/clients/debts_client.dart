// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/collect_result.dart';
import '../models/debt_response.dart';
import '../models/waive_request.dart';

part 'debts_client.g.dart';

@RestApi()
abstract class DebtsClient {
  factory DebtsClient(Dio dio, {String? baseUrl}) = _DebtsClient;

  /// Thu nợ ngay từ số dư dùng được của ví (cũ nhất trước)
  @POST('/me/debts/collect')
  Future<CollectResult> postMeDebtsCollect();

  /// [Admin] Miễn một khoản nợ (không gỡ lệnh cấm đấu giá)
  @POST('/admin/debts/{id}/waive')
  Future<DebtResponse> postAdminDebtsIdWaive({
    @Path('id') required int id,
    @Body() required WaiveRequest body,
  });

  /// Nợ phạt / phí kho của tôi
  @GET('/me/debts')
  Future<List<DebtResponse>> getMeDebts();
}
