// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/page_response_transaction_response.dart';
import '../models/payment_response.dart';
import '../models/top_up_request.dart';
import '../models/wallet_response.dart';
import '../models/withdraw_create_request.dart';
import '../models/withdraw_response.dart';

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

  /// Nạp tiền qua VNPay sandbox — trả về paymentUrl để mở trình duyệt
  @POST('/wallet/top-up')
  Future<PaymentResponse> postWalletTopUp({@Body() required TopUpRequest body});

  /// [DEV] Giả lập VNPay trả về thành công (chỉ khi app.payment.simulate-enabled=true)
  @POST('/payments/{code}/simulate')
  Future<PaymentResponse> postPaymentsCodeSimulate({
    @Path('code') required String code,
  });

  /// Số dư ví
  @GET('/wallet')
  Future<WalletResponse> getWallet();

  /// Lịch sử giao dịch ví (sổ cái)
  @GET('/wallet/transactions')
  Future<PageResponseTransactionResponse> getWalletTransactions({
    @Query('page') int? page = 0,
    @Query('size') int? size = 20,
  });

  /// Trạng thái một thanh toán
  @GET('/payments/{code}')
  Future<PaymentResponse> getPaymentsCode({@Path('code') required String code});

  /// Return URL của VNPay
  @GET('/payments/vnpay/return')
  Future<Map<String, String>> getPaymentsVnpayReturn({
    @Query('params') required Map<String, String> params,
  });

  /// IPN VNPay gọi về (server-to-server)
  @GET('/payments/vnpay/ipn')
  Future<Map<String, String>> getPaymentsVnpayIpn({
    @Query('params') required Map<String, String> params,
  });
}
