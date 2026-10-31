// Backend thu nhỏ chạy trong bộ nhớ cho chế độ USE_MOCK=true.
//
// Cài đúng nghiệp vụ trong docs/SRS.txt (tách đơn theo shop, giữ hàng, escrow, sổ cái ví,
// ký gửi → kiểm định → lô, bộ máy chạy phiên đấu giá) để app chạy trọn luồng khi chưa có
// backend Spring Boot. Các repository `Fake...` trong features/*/data gọi vào đây.
//
// Tài khoản mẫu (mật khẩu đều là 123456):
//   minhanh@rebook.vn  — người dùng, đã có shop, đã đăng ký phiên đang LIVE
//   khoa@rebook.vn     — người dùng chưa có shop
//   staff@rebook.vn    — nhân viên kho / kiểm định
//   admin@rebook.vn    — quản trị
library;

import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/session_controller.dart'
    show currentUserProvider;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/rules.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'fake_store.g.dart';
part 'fake_catalog.dart';
part 'fake_seed.dart';
part 'fake_commerce.dart';
part 'fake_consignment.dart';
part 'fake_auction.dart';

/// Lỗi nghiệp vụ giống backend thật.
Never fail(String code, [int status = 409]) =>
    throw ServerException(status, code: code, message: code);

class _Account {
  _Account(this.user, this.password);
  AppUser user;
  final String password;
}

class _ListingRow {
  _ListingRow(this.listing, this.shopOwnerId);
  Listing listing;
  final String shopOwnerId;
}

class _LotRow {
  _LotRow(
    this.lot, {
    required this.reserve,
    required this.consignmentId,
    required this.sellerId,
  });
  Lot lot;
  int reserve;
  final String consignmentId;
  final String sellerId;
  String? leaderUserId;
  final bids = <Bid>[];
}

class FakeStore {
  FakeStore() {
    _seed();
  }

  final rnd = Random(7);
  var _seq = 1000;
  String _id(String prefix) => '$prefix${++_seq}';

  /// Người đang đăng nhập (chế độ mock). Feature auth đặt giá trị này.
  String? currentUserId;

  FeeConfig fees = const FeeConfig();
  SystemConfig config = const SystemConfig(
    fixedPriceFeePercent: 5,
    buyerPremiumPercent: 10,
    sellerCommissionPercent: 15,
    storageFeePerDay: 5000,
    storageFreeDays: 14,
    orderPaymentTimeoutMin: 15,
    auctionPaymentTimeoutHours: 48,
    depositLimitMultiplier: 10,
    auctionBanDays: 90,
    bidTiers: defaultBidTiers,
  );

  final _accounts = <String, _Account>{};
  final _otps = <String, String>{};
  final _pendingRegistrations = <String, _Account>{};
  final shops = <String, Shop>{};
  final _shopOwner = <String, String>{}; // shopId -> userId
  final addresses = <String, List<Address>>{};
  final categories = <Category>[];
  final _listings = <String, _ListingRow>{};
  final _cart = <String, List<CartItem>>{};
  final orders = <String, Order>{};
  final _orderBuyer = <String, String>{};
  final _orderSellerPaid = <String, bool>{};
  final reviews = <String, List<Review>>{}; // shopId -> reviews
  final wallets = <String, Wallet>{};
  final txns = <String, List<WalletTxn>>{};
  final withdrawals = <Withdrawal>[];
  final activityLogs = <ActivityLog>[];
  final secondChances =
      <String, List<SecondChanceOffer>>{}; // userId -> lời mời
  final _withdrawalOwner = <String, String>{};
  final notifications = <String, List<AppNotification>>{};
  final payments = <String, Payment>{};
  final _paymentTarget =
      <String, ({String userId, List<String> orderIds, bool topUp})>{};
  final consignments = <String, Consignment>{};
  final warehouse = <String, WarehouseItem>{};
  final sessions = <String, AuctionSession>{};
  final _lots = <String, _LotRow>{};
  final registrations = <String, Registration>{}; // id -> reg
  final _registrationOwner = <String, String>{};
  final _watchers = <String, Set<String>>{}; // lotId -> userIds
  final _sessionEvents = <String, StreamController<AuctionEvent>>{};
  final _changes = StreamController<String>.broadcast();
  Timer? _engine;
  final _proxies = <String, ({String userId, int max})>{};
  final _breaks = <String, DateTime>{};
  final _pausedRemaining = <String, Duration>{};

  /// Phát tên vùng dữ liệu vừa đổi ('orders', 'wallet', 'notifications'...) để màn hình tải lại.
  Stream<String> get changes => _changes.stream;
  void _changed(String area) => _changes.add(area);

  // ───────────────────────── auth ─────────────────────────

  String get _uid => currentUserId ?? fail(ErrorCodes.invalidCredentials, 401);
  AppUser get me => _accountById(_uid).user;

  AppUser login(String email, String password) {
    final acc = _accounts[email.trim().toLowerCase()];
    if (acc == null || acc.password != password) {
      fail(ErrorCodes.invalidCredentials, 401);
    }
    if (acc.user.locked) fail(ErrorCodes.invalidCredentials, 403);
    currentUserId = acc.user.id;
    _ensureEngine();
    return acc.user;
  }

  /// Đăng ký: gửi OTP (mock: luôn là 123456).
  void register(String fullName, String email, String phone, String password) {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) fail(ErrorCodes.emailTaken);
    final user = AppUser(
      id: _id('u'),
      email: key,
      fullName: fullName,
      phone: phone,
      role: UserRole.user,
      phoneVerified: false,
      hasShop: false,
      createdAt: DateTime.now(),
    );
    _pendingRegistrations[key] = _Account(user, password);
    _otps[key] = '123456';
  }

  void sendOtp(String email) {
    final key = email.trim().toLowerCase();
    if (!_accounts.containsKey(key) &&
        !_pendingRegistrations.containsKey(key)) {
      fail(ErrorCodes.notFound, 404);
    }
    _otps[key] = '123456';
  }

  AppUser verifyOtp(String email, String code) {
    final key = email.trim().toLowerCase();
    if (_otps[key] != code) fail(ErrorCodes.invalidOtp, 400);
    _otps.remove(key);
    final pending = _pendingRegistrations.remove(key);
    if (pending != null) {
      pending.user = pending.user.copyWith(phoneVerified: true);
      _accounts[key] = pending;
      wallets[pending.user.id] = const Wallet(available: 0, held: 0);
    }
    final acc = _accounts[key]!;
    currentUserId = acc.user.id;
    _ensureEngine();
    return acc.user;
  }

  void resetPassword(String email, String code, String newPassword) {
    final key = email.trim().toLowerCase();
    if (_otps[key] != code) fail(ErrorCodes.invalidOtp, 400);
    final acc = _accounts[key] ?? fail(ErrorCodes.notFound, 404);
    _accounts[key] = _Account(acc.user, newPassword);
    _otps.remove(key);
  }

  _Account _accountById(String id) => _accounts.values.firstWhere(
    (a) => a.user.id == id,
    orElse: () => fail(ErrorCodes.notFound, 404),
  );

  AppUser updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) {
    final acc = _accountById(_uid);
    acc.user = acc.user.copyWith(
      fullName: fullName,
      phone: phone ?? acc.user.phone,
      avatarUrl: avatarUrl ?? acc.user.avatarUrl,
    );
    return acc.user;
  }

  List<AppUser> allUsers() => _accounts.values.map((a) => a.user).toList();

  AppUser setLocked(String userId, {required bool locked}) {
    final acc = _accountById(userId);
    acc.user = acc.user.copyWith(locked: locked);
    _log(
      locked ? AdminAction.userLocked : AdminAction.userUnlocked,
      target: acc.user.email,
    );
    return acc.user;
  }

  // ───────────────────────── addresses ─────────────────────────

  List<Address> myAddresses() => List.of(addresses[_uid] ?? const []);

  Address saveAddress(Address a) {
    final list = addresses.putIfAbsent(_uid, () => []);
    final saved = a.id.isEmpty ? a.copyWith(id: _id('addr')) : a;
    if (saved.isDefault) {
      for (var i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
    }
    final idx = list.indexWhere((x) => x.id == saved.id);
    if (idx >= 0) {
      list[idx] = saved;
    } else {
      list.add(list.isEmpty ? saved.copyWith(isDefault: true) : saved);
    }
    return saved;
  }

  void deleteAddress(String id) =>
      addresses[_uid]?.removeWhere((a) => a.id == id);

  // ───────────────────────── wallet core ─────────────────────────

  Wallet walletOf(String userId) =>
      wallets[userId] ??= const Wallet(available: 0, held: 0);

  /// Ghi một dòng sổ cái và cập nhật số dư. [availableDelta]/[heldDelta] có thể âm.
  void _ledger(
    String userId,
    WalletTxnType type, {
    int availableDelta = 0,
    int heldDelta = 0,
    String? note,
    String? refType,
    String? refId,
  }) {
    final w = walletOf(userId);
    final next = Wallet(
      available: w.available + availableDelta,
      held: w.held + heldDelta,
    );
    wallets[userId] = next;
    txns
        .putIfAbsent(userId, () => [])
        .insert(
          0,
          WalletTxn(
            id: _id('tx'),
            type: type,
            amount: availableDelta != 0 ? availableDelta : heldDelta,
            balanceAfter: next.available,
            createdAt: DateTime.now(),
            note: note,
            refType: refType,
            refId: refId,
          ),
        );
    _changed('wallet');
  }

  void notify(
    String userId,
    NotificationType type,
    String title,
    String body, [
    String? link,
  ]) {
    notifications
        .putIfAbsent(userId, () => [])
        .insert(
          0,
          AppNotification(
            id: _id('n'),
            type: type,
            title: title,
            body: body,
            isRead: false,
            createdAt: DateTime.now(),
            link: link,
          ),
        );
    _changed('notifications');
  }

  void dispose() {
    _engine?.cancel();
    for (final c in _sessionEvents.values) {
      c.close();
    }
    _changes.close();
  }
}

@Riverpod(keepAlive: true)
FakeStore fakeStore(Ref ref) {
  final store = FakeStore();
  ref.onDispose(store.dispose);
  // Mở lại app: phiên đăng nhập khôi phục từ token đã lưu → backend giả biết "tôi" là ai.
  ref.listen(
    currentUserProvider,
    (_, user) => store.currentUserId = user?.id,
    fireImmediately: true,
  );
  // Backend giả tự đổi dữ liệu (bộ máy đấu giá, hết hạn thanh toán...) → báo cho UI.
  final sub = store.changes.listen(
    (area) => ref.read(dataChangesProvider.notifier).bump(area),
  );
  ref.onDispose(sub.cancel);
  return store;
}

/// Giả lập độ trễ mạng và đổi lỗi thành [AppException] giống repository thật.
Future<T> fakeCall<T>(T Function() run, {int ms = 220}) => guardApi(() async {
  await Future<void>.delayed(Duration(milliseconds: ms));
  return run();
});
