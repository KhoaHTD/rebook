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
        final res = await _client.auth.postAuthLogin(
          body: api.LoginRequest(email: email, password: password),
        );
        final access = res.accessToken;
        final refresh = res.refreshToken;
        if (access == null || refresh == null) {
          throw const UnauthorizedException();
        }
        return AuthTokens(accessToken: access, refreshToken: refresh);
      });
}
