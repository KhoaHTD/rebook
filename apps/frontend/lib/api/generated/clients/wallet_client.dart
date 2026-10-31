// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/payment_dto.dart';
import '../models/top_up_request.dart';
import '../models/wallet_dto.dart';
import '../models/wallet_transaction_page.dart';
import '../models/withdrawal_dto.dart';
import '../models/withdrawal_request.dart';

part 'wallet_client.g.dart';

@RestApi()
abstract class WalletClient {
  factory WalletClient(Dio dio, {String? baseUrl}) = _WalletClient;

  @GET('/wallet')
  Future<WalletDto> getWallet();

  @GET('/wallet/transactions')
  Future<WalletTransactionPage> listWalletTransactions({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });

  @POST('/wallet/top-up')
  Future<PaymentDto> topUp({@Body() required TopUpRequest body});

  @GET('/wallet/withdrawals')
  Future<List<WithdrawalDto>> listWithdrawals();

  /// Tạo yêu cầu rút tiền. Backend kiểm tra thông tin ngân hàng và available_balance đủ số tiền; ví chỉ bị trừ khi Admin duyệt (SRS 8.1).
  @POST('/wallet/withdrawals')
  Future<WithdrawalDto> requestWithdrawal({
    @Body() required WithdrawalRequest body,
  });
}
