import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auth/domain/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final api.RestClient _client;

  @override
  Future<AuthTokens> login({required String email, required String password}) =>
      guardApi(() async {
        final pair = await _client.auth.login(
          body: api.LoginRequest(email: email, password: password),
        );
        return AuthTokens(
          accessToken: pair.accessToken,
          refreshToken: pair.refreshToken,
        );
      });
}
