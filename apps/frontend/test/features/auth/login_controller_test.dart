import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auth/data/auth_repository_provider.dart';
import 'package:book_marketplace/features/auth/data/fake_auth_repository.dart';
import 'package:book_marketplace/features/auth/presentation/providers/login_controller.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late _MockTokenStorage storage;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const AuthTokens(accessToken: '', refreshToken: ''));
  });

  setUp(() async {
    storage = _MockTokenStorage();
    when(() => storage.read()).thenAnswer((_) async => null);
    when(() => storage.write(any())).thenAnswer((_) async {});
    container = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    container.listen(sessionControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
  });

  test('chưa có token -> signedOut', () {
    expect(container.read(sessionControllerProvider), SessionStatus.signedOut);
  });

  test('đăng nhập thành công -> lưu token và signedIn', () async {
    container.listen(loginControllerProvider, (_, _) {});
    await container
        .read(loginControllerProvider.notifier)
        .login(email: 'a@b.vn', password: '123456');

    expect(container.read(loginControllerProvider).hasError, isFalse);
    expect(container.read(sessionControllerProvider), SessionStatus.signedIn);
    verify(() => storage.write(any())).called(1);
  });

  test('sai mật khẩu -> UnauthorizedException, vẫn signedOut', () async {
    container.listen(loginControllerProvider, (_, _) {});
    await container
        .read(loginControllerProvider.notifier)
        .login(email: 'a@b.vn', password: '1');

    expect(
      container.read(loginControllerProvider).error,
      isA<UnauthorizedException>(),
    );
    expect(container.read(sessionControllerProvider), SessionStatus.signedOut);
    verifyNever(() => storage.write(any()));
  });
}
