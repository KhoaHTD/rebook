// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/auth_response.dart';
import '../models/forgot_password_request.dart';
import '../models/login_request.dart';
import '../models/otp_sent_response.dart';
import '../models/refresh_request.dart';
import '../models/register_request.dart';
import '../models/reset_password_request.dart';
import '../models/send_otp_request.dart';
import '../models/verify_otp_request.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Xác thực OTP email / SĐT (cần đăng nhập)
  @POST('/auth/verify-otp')
  Future<void> postAuthVerifyOtp({@Body() required VerifyOtpRequest body});

  /// Gửi OTP xác thực email / SĐT (cần đăng nhập)
  @POST('/auth/send-otp')
  Future<OtpSentResponse> postAuthSendOtp({
    @Body() required SendOtpRequest body,
  });

  @POST('/auth/reset-password')
  Future<void> postAuthResetPassword({
    @Body() required ResetPasswordRequest body,
  });

  /// Đăng ký — gửi OTP xác thực email
  @POST('/auth/register')
  Future<AuthResponse> postAuthRegister({
    @Body() required RegisterRequest body,
  });

  /// Đổi refresh token lấy cặp token mới
  @POST('/auth/refresh')
  Future<AuthResponse> postAuthRefresh({@Body() required RefreshRequest body});

  @POST('/auth/logout')
  Future<void> postAuthLogout({@Body() required RefreshRequest body});

  @POST('/auth/login')
  Future<AuthResponse> postAuthLogin({@Body() required LoginRequest body});

  @POST('/auth/forgot-password')
  Future<OtpSentResponse> postAuthForgotPassword({
    @Body() required ForgotPasswordRequest body,
  });
}
