// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_response.dart';
import '../models/email_request.dart';
import '../models/login_request.dart';
import '../models/otp_sent_response.dart';
import '../models/refresh_request.dart';
import '../models/register_request.dart';
import '../models/reset_password_request.dart';
import '../models/verify_otp_request.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  @POST('/auth/register')
  Future<OtpSentResponse> register({@Body() required RegisterRequest body});

  @POST('/auth/verify-otp')
  Future<AuthResponse> verifyOtp({@Body() required VerifyOtpRequest body});

  @POST('/auth/resend-otp')
  Future<OtpSentResponse> resendOtp({@Body() required EmailRequest body});

  @POST('/auth/login')
  Future<AuthResponse> login({@Body() required LoginRequest body});

  @POST('/auth/refresh')
  Future<AuthResponse> refresh({@Body() required RefreshRequest body});

  @POST('/auth/forgot-password')
  Future<OtpSentResponse> forgotPassword({@Body() required EmailRequest body});

  @POST('/auth/reset-password')
  Future<void> resetPassword({@Body() required ResetPasswordRequest body});
}
