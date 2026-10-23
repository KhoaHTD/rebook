import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/auth/data/fake_auth_repository.dart';
import 'package:book_marketplace/features/auth/presentation/providers/auth_controller.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

void main() {
  late FakeStore store;
  late FakeAuthRepository repo;

  setUp(() {
    store = FakeStore();
    repo = FakeAuthRepository(store);
  });
  tearDown(() => store.dispose());

  test('đăng nhập đúng mật khẩu trả token và người dùng', () async {
    final (tokens, user) = await repo.login('minhanh@rebook.vn', '123456');
    expect(tokens.accessToken, isNotEmpty);
    expect(user.hasShop, isTrue);
    expect(store.currentUserId, user.id);
  });

  test('sai mật khẩu → INVALID_CREDENTIALS', () async {
    await expectLater(
      repo.login('minhanh@rebook.vn', 'sai'),
      throwsA(
        isA<ServerException>().having(
          (e) => e.code,
          'code',
          ErrorCodes.invalidCredentials,
        ),
      ),
    );
  });

  test('đăng ký → OTP 123456 → đăng nhập luôn', () async {
    await repo.register(
      fullName: 'Lan',
      email: 'lan@rebook.vn',
      phone: '0901234567',
      password: '123456',
    );
    await expectLater(
      repo.verifyOtp('lan@rebook.vn', '000000'),
      throwsA(isA<ServerException>()),
    );
    final (_, user) = await repo.verifyOtp('lan@rebook.vn', '123456');
    expect(user.email, 'lan@rebook.vn');
  });

  test('email đã dùng → EMAIL_TAKEN', () async {
    await expectLater(
      repo.register(
        fullName: 'X',
        email: 'khoa@rebook.vn',
        phone: '0901234567',
        password: '123456',
      ),
      throwsA(
        isA<ServerException>().having(
          (e) => e.code,
          'code',
          ErrorCodes.emailTaken,
        ),
      ),
    );
  });

  test('quên mật khẩu → đặt lại → đăng nhập bằng mật khẩu mới', () async {
    await repo.forgotPassword('khoa@rebook.vn');
    await repo.resetPassword('khoa@rebook.vn', '123456', 'moi12345');
    final (_, user) = await repo.login('khoa@rebook.vn', 'moi12345');
    expect(user.email, 'khoa@rebook.vn');
  });

  test('AuthValidators', () {
    expect(AuthValidators.email('a@b.vn'), isTrue);
    expect(AuthValidators.email('ab.vn'), isFalse);
    expect(AuthValidators.phone('0901234567'), isTrue);
    expect(AuthValidators.phone('12345'), isFalse);
    expect(AuthValidators.otp('123456'), isTrue);
    expect(AuthValidators.password('12345'), isFalse);
  });
}
