import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';

part 'session_controller.g.dart';

enum SessionStatus { unknown, signedIn, signedOut }

/// Trạng thái đăng nhập toàn app. Router, AuthInterceptor và màn hình đều đọc từ đây.
/// Màn login (features/auth) gọi [signIn]; nút đăng xuất gọi [signOut].
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  @override
  SessionStatus build() {
    _restore();
    return SessionStatus.unknown;
  }

  Future<void> _restore() async {
    final tokens = await ref.read(tokenStorageProvider).read();
    state = tokens == null ? SessionStatus.signedOut : SessionStatus.signedIn;
  }

  Future<void> signIn(AuthTokens tokens) async {
    await ref.read(tokenStorageProvider).write(tokens);
    state = SessionStatus.signedIn;
  }

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    state = SessionStatus.signedOut;
  }
}
