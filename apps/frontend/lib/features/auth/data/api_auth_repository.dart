import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auth/domain/auth_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Backend cấp token ngay khi đăng ký và bắt xác thực OTP *khi đã đăng nhập*
/// (`/auth/verify-otp` không nhận email). Nên giữ token của lần đăng ký ở đây,
/// chưa lưu vào TokenStorage — tài khoản chưa xác thực thì app chưa coi là đăng nhập.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final api.RestClient _client;
  AuthTokens? _pending;

  api.RestClient _asPending() {
    final tokens = _pending;
    if (tokens == null) {
      throw const ServerException(
        401,
        code: 'INVALID_OTP',
        message: 'Phiên đăng ký đã hết, hãy đăng ký lại hoặc đăng nhập.',
      );
    }
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
      ),
    );
    return api.RestClient(dio);
  }

  @override
  Future<(AuthTokens, AppUser)> login(String email, String password) =>
      guardApi(() async {
        final res = await _client.auth.postAuthLogin(
          body: api.LoginRequest(email: email, password: password),
        );
        return res.toDomain();
      });

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) => guardApi(() async {
    final res = await _client.auth.postAuthRegister(
      body: api.RegisterRequest(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      ),
    );
    _pending = res.toDomain().$1;
    // Môi trường dev trả mã OTP ngay trong phản hồi (không gửi email thật).
    if (res.devOtp != null) debugPrint('DEV OTP cho $email: ${res.devOtp}');
  });

  @override
  Future<(AuthTokens, AppUser)> verifyOtp(String email, String code) =>
      guardApi(() async {
        final authed = _asPending();
        await authed.auth.postAuthVerifyOtp(
          body: api.VerifyOtpRequest(
            purpose: api.OtpPurpose.verifyEmail,
            code: code,
          ),
        );
        final user = (await authed.user.getMe()).toDomain();
        final tokens = _pending!;
        _pending = null;
        return (tokens, user);
      });

  @override
  Future<void> resendOtp(String email) => guardApi(() async {
    final res = await _asPending().auth.postAuthSendOtp(
      body: const api.SendOtpRequest(purpose: api.OtpPurpose.verifyEmail),
    );
    if (res.devOtp != null) debugPrint('DEV OTP cho $email: ${res.devOtp}');
  });

  @override
  Future<void> forgotPassword(String email) => guardApi(() async {
    final res = await _client.auth.postAuthForgotPassword(
      body: api.ForgotPasswordRequest(email: email),
    );
    if (res.devOtp != null) debugPrint('DEV OTP cho $email: ${res.devOtp}');
  });

  @override
  Future<void> resetPassword(String email, String code, String newPassword) =>
      guardApi(
        () => _client.auth.postAuthResetPassword(
          body: api.ResetPasswordRequest(
            email: email,
            code: code,
            newPassword: newPassword,
          ),
        ),
      );
}
