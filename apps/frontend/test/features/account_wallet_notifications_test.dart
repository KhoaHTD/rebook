import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/account/data/fake_account_repository.dart';
import 'package:book_marketplace/features/notifications/data/fake_notifications_repository.dart';
import 'package:book_marketplace/features/wallet/data/fake_wallet_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/user.dart';

void main() {
  late FakeStore store;

  setUp(() => store = FakeStore()..login('minhanh@rebook.vn', '123456'));
  tearDown(() => store.dispose());

  group('account', () {
    test('sửa hồ sơ', () async {
      final repo = FakeAccountRepository(store);
      final u = await repo.updateProfile(fullName: 'Minh Anh');
      expect(u.fullName, 'Minh Anh');
      expect((await repo.me()).fullName, 'Minh Anh');
    });

    test('thêm địa chỉ mặc định → các địa chỉ khác bỏ mặc định', () async {
      final repo = FakeAccountRepository(store);
      await repo.saveAddress(
        const Address(
          id: '',
          receiver: 'A',
          phone: '0900000000',
          province: 'Đà Nẵng',
          district: 'Hải Châu',
          ward: 'Thạch Thang',
          detail: '1 Bạch Đằng',
          isDefault: true,
        ),
      );
      final list = await repo.addresses();
      expect(list.where((a) => a.isDefault), hasLength(1));
      expect(list.firstWhere((a) => a.isDefault).province, 'Đà Nẵng');
    });
  });

  group('wallet', () {
    test('tạo yêu cầu rút lưu thông tin ngân hàng, chưa trừ ví (trừ khi Admin duyệt)', () async {
      final repo = FakeWalletRepository(store);
      final before = (await repo.wallet()).available;
      final w = await repo.requestWithdrawal(
        100000,
        bankName: 'Vietcombank',
        accountNumber: '0011004567890',
        accountName: 'NGUYEN VAN A',
        note: 'Rút thử',
      );
      expect(w.bankName, 'Vietcombank');
      expect(w.bankAccountName, 'NGUYEN VAN A');
      expect(w.note, 'Rút thử');
      expect((await repo.wallet()).available, before);
      expect(await repo.withdrawals(), isNotEmpty);
    });

    test('rút quá số dư → INSUFFICIENT_BALANCE', () async {
      final repo = FakeWalletRepository(store);
      final w = await repo.wallet();
      await expectLater(
        repo.requestWithdrawal(
          w.available + 1,
          bankName: 'ACB',
          accountNumber: '123456',
          accountName: 'A',
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            ErrorCodes.insufficientBalance,
          ),
        ),
      );
    });

    test('nạp tiền tạo phiên thanh toán chờ', () async {
      final p = await FakeWalletRepository(store).topUp(200000);
      expect(p.amount, 200000);
      expect(p.paymentUrl, startsWith('mock://'));
    });
  });

  test('đánh dấu đã đọc tất cả thông báo', () async {
    final repo = FakeNotificationsRepository(store);
    await repo.markRead(null);
    expect((await repo.list()).every((n) => n.isRead), isTrue);
  });
}
