import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';

part 'session_controller.g.dart';

enum AuthStatus { unknown, signedIn, signedOut }

/// Trạng thái đăng nhập toàn app.
class AuthSession {
  const AuthSession(this.status, [this.user]);

  static const unknown = AuthSession(AuthStatus.unknown);
  static const signedOut = AuthSession(AuthStatus.signedOut);

  final AuthStatus status;
  final AuthUser? user;

  bool get isSignedIn => status == AuthStatus.signedIn && user != null;
}

/// Router, AuthInterceptor và màn hình đều đọc từ đây.
/// Feature auth gọi [signIn]; nút đăng xuất gọi [signOut].
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  @override
  AuthSession build() {
    _restore();
    return AuthSession.unknown;
  }

  Future<void> _restore() async {
    final storage = ref.read(tokenStorageProvider);
    final tokens = await storage.read();
    final user = await storage.readUser();
    state = tokens == null || user == null
        ? AuthSession.signedOut
        : AuthSession(AuthStatus.signedIn, user);
  }

  Future<void> signIn(AuthTokens tokens, AuthUser user) async {
    final storage = ref.read(tokenStorageProvider);
    await storage.write(tokens);
    await storage.writeUser(user);
    state = AuthSession(AuthStatus.signedIn, user);
  }

  /// Cập nhật thông tin người dùng (vd vừa mở shop, đổi tên).
  Future<void> updateUser(AuthUser user) async {
    if (!state.isSignedIn) return;
    await ref.read(tokenStorageProvider).writeUser(user);
    state = AuthSession(AuthStatus.signedIn, user);
  }

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    state = AuthSession.signedOut;
  }
}

/// Người đang đăng nhập, hoặc null.
@Riverpod(keepAlive: true)
AuthUser? currentUser(Ref ref) => ref.watch(sessionControllerProvider).user;
