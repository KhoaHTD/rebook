import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Đăng nhập / đăng ký (SRS 5.1). Đăng ký xác thực qua OTP gửi email.
abstract interface class AuthRepository {
  Future<(AuthTokens, AppUser)> login(String email, String password);

  /// Tạo tài khoản chờ xác thực và gửi OTP tới [email].
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  Future<(AuthTokens, AppUser)> verifyOtp(String email, String code);

  Future<void> resendOtp(String email);

  /// Gửi OTP đặt lại mật khẩu.
  Future<void> forgotPassword(String email);

  Future<void> resetPassword(String email, String code, String newPassword);
}
