import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auth/domain/auth_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final api.RestClient _client;

  @override
  Future<(AuthTokens, AppUser)> login(String email, String password) =>
      guardApi(() async {
        final res = await _client.auth.login(
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
  }) => guardApi(
    () => _client.auth.register(
      body: api.RegisterRequest(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      ),
    ),
  );

  @override
  Future<(AuthTokens, AppUser)> verifyOtp(String email, String code) =>
      guardApi(() async {
        final res = await _client.auth.verifyOtp(
          body: api.VerifyOtpRequest(email: email, code: code),
        );
        return res.toDomain();
      });

  @override
  Future<void> resendOtp(String email) => guardApi(
    () => _client.auth.resendOtp(body: api.EmailRequest(email: email)),
  );

  @override
  Future<void> forgotPassword(String email) => guardApi(
    () => _client.auth.forgotPassword(body: api.EmailRequest(email: email)),
  );

  @override
  Future<void> resetPassword(String email, String code, String newPassword) =>
      guardApi(
        () => _client.auth.resetPassword(
          body: api.ResetPasswordRequest(
            email: email,
            code: code,
            newPassword: newPassword,
          ),
        ),
      );
}
