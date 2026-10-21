import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auth/domain/auth_repository.dart';

/// Chế độ mock: mật khẩu bất kỳ dài từ 6 ký tự đều đăng nhập được.
class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (password.length < 6) throw const UnauthorizedException();
    return const AuthTokens(
      accessToken: 'fake-access',
      refreshToken: 'fake-refresh',
    );
  }
}
