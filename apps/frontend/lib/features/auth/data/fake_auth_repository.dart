import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/features/auth/domain/auth_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Mọi tài khoản mẫu có mật khẩu 123456; OTP luôn là 123456.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._store);

  final FakeStore _store;

  (AuthTokens, AppUser) _session(AppUser user) => (
    AuthTokens(
      accessToken: 'mock-access-${user.id}',
      refreshToken: 'mock-refresh-${user.id}',
    ),
    user,
  );

  @override
  Future<(AuthTokens, AppUser)> login(String email, String password) =>
      fakeCall(() => _session(_store.login(email, password)), ms: 450);

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) => fakeCall(() => _store.register(fullName, email, phone, password));

  @override
  Future<(AuthTokens, AppUser)> verifyOtp(String email, String code) =>
      fakeCall(() => _session(_store.verifyOtp(email, code)));

  @override
  Future<void> resendOtp(String email) => fakeCall(() => _store.sendOtp(email));

  @override
  Future<void> forgotPassword(String email) =>
      fakeCall(() => _store.sendOtp(email));

  @override
  Future<void> resetPassword(String email, String code, String newPassword) =>
      fakeCall(() => _store.resetPassword(email, code, newPassword));
}
