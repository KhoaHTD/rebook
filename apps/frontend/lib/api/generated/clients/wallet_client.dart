// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/bank_account_dto.dart';
import '../models/favorite_request.dart';
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

  /// Tài khoản ngân hàng tôi đã dùng để rút tiền (màn "Gần đây"), yêu thích đứng đầu rồi tới lần dùng mới nhất. Backend tự lưu / cập nhật khi tạo yêu cầu rút tiền.
  @GET('/wallet/bank-accounts')
  Future<List<BankAccountDto>> listBankAccounts();

  /// Đánh dấu / bỏ đánh dấu yêu thích một tài khoản ngân hàng đã lưu.
  @POST('/wallet/bank-accounts/{id}/favorite')
  Future<BankAccountDto> setBankAccountFavorite({
    @Path('id') required String id,
    @Body() required FavoriteRequest body,
  });
}
