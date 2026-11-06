// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/bank_account_response.dart';
import '../models/page_response_transaction_response.dart';
import '../models/payment_response.dart';
import '../models/top_up_request.dart';
import '../models/wallet_response.dart';
import '../models/withdraw_create_request.dart';
import '../models/withdraw_response.dart';
import '../models/withdrawable_response.dart';

part 'wallet_client.g.dart';

@RestApi()
abstract class WalletClient {
  factory WalletClient(Dio dio, {String? baseUrl}) = _WalletClient;

  @GET('/wallet/withdrawals')
  Future<List<WithdrawResponse>> getWalletWithdrawals();

  /// Tạo yêu cầu rút tiền (Admin duyệt)
  @POST('/wallet/withdrawals')
  Future<WithdrawResponse> postWalletWithdrawals({
    @Body() required WithdrawCreateRequest body,
  });

  /// Nạp tiền qua ZaloPay sandbox — trả về paymentUrl để mở trình duyệt
  @POST('/wallet/top-up')
  Future<PaymentResponse> postWalletTopUp({@Body() required TopUpRequest body});

  /// Đánh dấu yêu thích một tài khoản ngân hàng đã lưu
  @POST('/wallet/bank-accounts/{id}/favorite')
  Future<BankAccountResponse> postWalletBankAccountsIdFavorite({
    @Path('id') required int id,
  });

  @DELETE('/wallet/bank-accounts/{id}/favorite')
  Future<BankAccountResponse> deleteWalletBankAccountsIdFavorite({
    @Path('id') required int id,
  });

  /// [DEV] Giả lập cổng thanh toán trả về thành công (chỉ khi app.payment.simulate-enabled=true)
  @POST('/payments/{code}/simulate')
  Future<PaymentResponse> postPaymentsCodeSimulate({
    @Path('code') required String code,
  });

  /// Callback ZaloPay (server-to-server)
  @POST('/payments/zalopay/callback')
  Future<dynamic> postPaymentsZalopayCallback({
    @Body() required Map<String, dynamic> body,
  });

  /// Số dư ví
  @GET('/wallet')
  Future<WalletResponse> getWallet();

  /// Số tiền rút được ngay (trừ tiền mới nạp còn bị khoá)
  @GET('/wallet/withdrawable')
  Future<WithdrawableResponse> getWalletWithdrawable();

  /// Lịch sử giao dịch ví (sổ cái)
  @GET('/wallet/transactions')
  Future<PageResponseTransactionResponse> getWalletTransactions({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });

  /// Tài khoản ngân hàng đã dùng để rút tiền (yêu thích trước, rồi mới dùng gần nhất)
  @GET('/wallet/bank-accounts')
  Future<List<BankAccountResponse>> getWalletBankAccounts();

  /// Trạng thái một thanh toán
  @GET('/payments/{code}')
  Future<PaymentResponse> getPaymentsCode({@Path('code') required String code});

  /// Redirect URL của ZaloPay: xác nhận giao dịch rồi hiện trang kết quả cho người dùng
  @GET('/payments/zalopay/return')
  Future<String> getPaymentsZalopayReturn({
    @Query('params') required Map<String, String> params,
  });
}
