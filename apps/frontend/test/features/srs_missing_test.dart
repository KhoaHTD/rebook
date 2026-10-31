import 'package:flutter_test/flutter_test.dart';

import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/core/utils/vietnamese.dart';
import 'package:book_marketplace/features/admin/data/fake_admin_repository.dart';
import 'package:book_marketplace/features/auction/data/fake_auction_repository.dart';
import 'package:book_marketplace/features/cart/data/fake_cart_repository.dart';
import 'package:book_marketplace/features/catalog/data/fake_catalog_repository.dart';
import 'package:book_marketplace/features/wallet/data/fake_wallet_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/data/vietnam_geo.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

/// Các mục bổ sung ngoài SRS gốc: sách yêu thích, phiên yêu thích, chọn món trong giỏ, thông tin ngân hàng khi rút,
/// trừ ví khi Admin duyệt, người duyệt, tọa độ địa chỉ.
void main() {
  late FakeStore store;
  tearDown(() => store.dispose());

  WithdrawalReceipt receipt(int amount) => WithdrawalReceipt(
    senderName: 'CTY REBOOK',
    transferredAt: DateTime.now(),
    amount: amount,
    proofImageUrl: 'mem://x',
  );

  group('sách yêu thích', () {
    late FakeCatalogRepository repo;
    setUp(() {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      repo = FakeCatalogRepository(store);
    });

    test('thả tim, mới nhất đứng đầu; bỏ tim thì gỡ khỏi danh sách', () async {
      final items = store.searchListings(const ListingQuery()).items;
      expect(await repo.favorites(), isEmpty);
      await repo.setFavorite(items[0].id, on: true);
      await repo.setFavorite(items[1].id, on: true);
      expect((await repo.favorites()).map((l) => l.id), [
        items[1].id,
        items[0].id,
      ]);
      await repo.setFavorite(items[1].id, on: false);
      expect((await repo.favorites()).map((l) => l.id), [items[0].id]);
    });

    test('tin không tồn tại → lỗi', () async {
      await expectLater(repo.setFavorite('nope', on: true), throwsA(anything));
    });
  });

  group('phiên yêu thích', () {
    test('theo dõi / bỏ theo dõi cả phiên', () async {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      final repo = FakeAuctionRepository(store);
      final s = (await repo.sessions()).first;
      expect(await repo.watchedSessions(), isEmpty);
      await repo.watchSession(s.id, on: true);
      expect((await repo.watchedSessions()).single.id, s.id);
      await repo.watchSession(s.id, on: false);
      expect(await repo.watchedSessions(), isEmpty);
    });
  });

  group('giỏ hàng: chọn món', () {
    late FakeCartRepository repo;
    late String firstItemId;
    setUp(() async {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      repo = FakeCartRepository(store);
      final listings = store.searchListings(const ListingQuery()).items;
      final a = listings.first;
      final b = listings.firstWhere((l) => l.shop.id != a.shop.id);
      store
        ..addToCart(a.id, 1)
        ..addToCart(b.id, 1);
      firstItemId = (await repo.cart()).groups.first.items.first.id;
    });

    test('chỉ tính các món đã chọn, ship tính lại theo các món này', () async {
      final all = await repo.cart();
      expect(all.groups, hasLength(2));
      final only = await repo.cart(itemIds: [firstItemId]);
      expect(only.groups, hasLength(1));
      expect(only.subtotal, all.groups.first.subtotal);
      expect(only.total, lessThan(all.total));
      expect((await repo.cart(itemIds: const [])).groups, isEmpty);
    });

    test('thanh toán chỉ các món đã chọn, món còn lại ở lại giỏ', () async {
      final result = await repo.checkout(
        addressId: (await repo.addresses()).first.id,
        method: PaymentMethod.cod,
        itemIds: [firstItemId],
      );
      expect(result.orders, hasLength(1));
      final left = await repo.cart();
      expect(left.groups, hasLength(1));
      expect(left.groups.first.items.first.id, isNot(firstItemId));
    });
  });

  group('rút tiền', () {
    setUp(() => store = FakeStore()..login('minhanh@rebook.vn', '123456'));

    Future<Withdrawal> request(FakeWalletRepository wallet, int amount) =>
        wallet.requestWithdrawal(
          amount,
          bankName: 'ACB',
          accountNumber: '123456789',
          accountName: 'NGUYEN MINH ANH',
        );

    test('lúc duyệt kiểm tra lại số dư (đã bị trừ bởi yêu cầu khác)', () async {
      final wallet = FakeWalletRepository(store);
      final all = (await wallet.wallet()).available;
      final big = await request(wallet, all);
      final small = await request(wallet, 1);
      expect((await wallet.wallet()).available, all);

      store.login('admin@rebook.vn', '123456');
      final admin = FakeAdminRepository(store);
      await admin.completeWithdrawal(small.id, receipt(1));
      await expectLater(
        admin.completeWithdrawal(big.id, receipt(big.amount)),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            ErrorCodes.insufficientBalance,
          ),
        ),
      );
    });

    test('duyệt xong: trừ ví, lưu người duyệt và thời gian duyệt', () async {
      final wallet = FakeWalletRepository(store);
      final before = (await wallet.wallet()).available;
      final w = await request(wallet, 200000);
      store.login('admin@rebook.vn', '123456');
      final done = await FakeAdminRepository(store)
          .completeWithdrawal(w.id, receipt(200000));
      expect(done.approvedBy, 'Admin ReBook');
      expect(done.approvedAt, isNotNull);
      store.login('minhanh@rebook.vn', '123456');
      expect((await wallet.wallet()).available, before - 200000);
    });
  });

  group('người duyệt', () {
    setUp(() => store = FakeStore()..login('admin@rebook.vn', '123456'));

    test('duyệt tin ghi người duyệt và thời gian', () async {
      final admin = FakeAdminRepository(store);
      final pending = await admin.listings(status: ListingStatus.pendingReview);
      final l = await admin.reviewListing(pending.first.id, approve: true);
      expect(l.reviewedBy, 'Admin ReBook');
      expect(l.reviewedAt, isNotNull);
    });
  });

  group('địa chỉ', () {
    test('63 tỉnh / thành đều tra được toạ độ tâm tỉnh', () {
      expect(VietnamGeo.provinceNames, hasLength(63));
      for (final n in VietnamGeo.provinceNames) {
        expect(VietnamGeo.province(n), isNotNull, reason: n);
      }
    });

    test('lưu và đọc lại loại địa chỉ', () {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      final base = store.myAddresses().first;
      expect(base.type, AddressType.home);
      final saved = store.saveAddress(base.copyWith(type: AddressType.office));
      expect(
        store.myAddresses().firstWhere((a) => a.id == saved.id).type,
        AddressType.office,
      );
    });

    test('lưu và đọc lại toạ độ đã ghim', () {
      store = FakeStore()..login('khoa@rebook.vn', '123456');
      final base = store.myAddresses().first;
      final saved = store.saveAddress(
        base.copyWith(latitude: 10.77, longitude: 106.69),
      );
      expect(saved.hasPin, isTrue);
      final again = store.myAddresses().firstWhere((a) => a.id == saved.id);
      expect(again.latitude, 10.77);
      expect(again.longitude, 106.69);
      expect(base.hasPin, isFalse);
    });
  });

  group('tài khoản ngân hàng đã dùng', () {
    late FakeWalletRepository wallet;
    setUp(() {
      store = FakeStore()..login('minhanh@rebook.vn', '123456');
      wallet = FakeWalletRepository(store);
    });

    test('yêu thích đứng đầu, rồi tới lần dùng mới nhất', () async {
      final list = await wallet.bankAccounts();
      expect(list.first.favorite, isTrue);
      expect(list.first.bankName, 'Vietcombank');
      expect(list[1].bankName, 'Techcombank');
    });

    test(
      'tạo yêu cầu rút tự lưu tài khoản mới, dùng lại thì không nhân đôi',
      () async {
        Future<void> withdraw(String number) => wallet.requestWithdrawal(
          10000,
          bankName: 'ACB',
          accountNumber: number,
          accountName: 'NGUYEN MINH ANH',
        );
        await withdraw('111222333');
        await withdraw('111222333');
        await withdraw('444555666');
        final acb = (await wallet.bankAccounts()).where(
          (a) => a.bankName == 'ACB',
        );
        expect(
          acb.map((a) => a.accountNumber),
          unorderedEquals(['111222333', '444555666']),
        );
      },
    );

    test('đánh dấu / bỏ yêu thích', () async {
      final tcb = (await wallet.bankAccounts()).firstWhere(
        (a) => a.bankName == 'Techcombank',
      );
      await wallet.setBankAccountFavorite(tcb.id, on: true);
      expect((await wallet.bankAccounts()).first.favorite, isTrue);
      await wallet.setBankAccountFavorite(tcb.id, on: false);
      expect(
        (await wallet.bankAccounts())
            .where((a) => a.favorite)
            .map((a) => a.bankName),
        ['Vietcombank'],
      );
    });
  });

  group('tên chủ tài khoản', () {
    test('in hoa, không dấu, bỏ ký tự lạ, gộp khoảng trắng', () {
      expect(bankAccountName('Nguyễn  Minh Ánh'), 'NGUYEN MINH ANH');
      // Giữ dấu cách cuối để người dùng còn gõ tiếp từ sau; form tự cắt khoảng trắng khi gửi.
      expect(bankAccountName('Đặng Văn Lực 123').trim(), 'DANG VAN LUC');
      expect(removeDiacritics('Ươm Mầm'), 'Uom Mam');
    });
  });
}
