// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/payment_dto.dart';

part 'payments_client.g.dart';

@RestApi()
abstract class PaymentsClient {
  factory PaymentsClient(Dio dio, {String? baseUrl}) = _PaymentsClient;

  /// App gọi lại sau khi người dùng quay về từ VNPay để biết kết quả (IPN đã cập nhật ở backend).
  @GET('/payments/{id}')
  Future<PaymentDto> getPayment({@Path('id') required String id});
}
