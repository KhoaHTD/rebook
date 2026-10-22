import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/features/auth/data/auth_repository_provider.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'auth_controller.g.dart';

/// Mọi hành động đăng nhập / đăng ký. Mỗi method trả về true nếu thành công;
/// lỗi nằm trong `state` để màn hình hiển thị.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<void> _signIn((AuthTokens, AppUser) result) => ref
      .read(sessionControllerProvider.notifier)
      .signIn(result.$1, result.$2.toAuthUser());

  Future<bool> login(String email, String password) => _run(() async {
    final result = await ref
        .read(authRepositoryProvider)
        .login(email.trim(), password);
    await _signIn(result);
  });

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) => _run(
    () => ref
        .read(authRepositoryProvider)
        .register(
          fullName: fullName.trim(),
          email: email.trim(),
          phone: phone.trim(),
          password: password,
        ),
  );

  Future<bool> verifyOtp(String email, String code) => _run(() async {
    final result = await ref
        .read(authRepositoryProvider)
        .verifyOtp(email, code.trim());
    await _signIn(result);
  });

  Future<bool> resendOtp(String email) =>
      _run(() => ref.read(authRepositoryProvider).resendOtp(email));

  Future<bool> forgotPassword(String email) =>
      _run(() => ref.read(authRepositoryProvider).forgotPassword(email.trim()));

  Future<bool> resetPassword(String email, String code, String newPassword) =>
      _run(
        () => ref
            .read(authRepositoryProvider)
            .resetPassword(email, code.trim(), newPassword),
      );
}

/// Kiểm tra dữ liệu form (thuần Dart để test được).
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^(0|\+84)\d{9,10}$');

  static bool email(String v) => _email.hasMatch(v.trim());
  static bool password(String v) => v.length >= 6;
  static bool phone(String v) => _phone.hasMatch(v.replaceAll(' ', ''));
  static bool otp(String v) => RegExp(r'^\d{6}$').hasMatch(v.trim());
}
