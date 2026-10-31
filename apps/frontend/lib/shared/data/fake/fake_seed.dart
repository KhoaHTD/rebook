part of 'fake_store.dart';

extension _Seed on FakeStore {
  void _seed() {
    final now = DateTime.now();

    // ── tài khoản ──
    AppUser user(
      String id,
      String email,
      String name, {
      UserRole role = UserRole.user,
      bool shop = false,
    }) => AppUser(
      id: id,
      email: email,
      fullName: name,
      role: role,
      phoneVerified: true,
      hasShop: shop,
      phone:
          '09${id.hashCode.abs().toString().padLeft(8, '0').substring(0, 8)}',
      createdAt: now.subtract(const Duration(days: 120)),
    );
    final people = [
      user('u1', 'minhanh@rebook.vn', 'Nguyễn Minh Anh', shop: true),
      user('u2', 'khoa@rebook.vn', 'Huỳnh Đăng Khoa'),
      user('u3', 'gacxep@rebook.vn', 'Trần Thu Hà', shop: true),
      user('u4', 'sachcuhn@rebook.vn', 'Lê Văn Phúc', shop: true),
      user('u5', 'devshelf@rebook.vn', 'Phạm Quang Huy', shop: true),
      user('u6', 'hathanh@rebook.vn', 'Đỗ Thị Hằng', shop: true),
      user('u90', 'staff@rebook.vn', 'Ngô Bảo Kho', role: UserRole.staff),
      user('u99', 'admin@rebook.vn', 'Admin ReBook', role: UserRole.admin),
    ];
    for (final u in people) {
      _accounts[u.email] = _Account(u, '123456');
      wallets[u.id] = const Wallet(available: 0, held: 0);
    }

    // ── shop ──
    Shop shop(
      String id,
      String owner,
      String name,
      String desc,
      double rating,
      int count,
    ) {
      _shopOwner[id] = owner;
      return Shop(
        id: id,
        userId: owner,
        name: name,
        description: desc,
        pickupAddress: 'Q.10, TP. Hồ Chí Minh',
        ratingAvg: rating,
        ratingCount: count,
        createdAt: now.subtract(const Duration(days: 90)),
      );
    }

    for (final s in [
      shop(
        's1',
        'u1',
        'Minh Anh Books',
        'Sách văn học và giáo trình còn mới, giao tại FPT.',
        4.8,
        42,
      ),
      shop(
        's3',
        'u3',
        'Gác Xép',
        'Văn học Việt bản in cũ, sách có chữ ký.',
        4.9,
        128,
      ),
      shop(
        's4',
        'u4',
        'Sách Cũ Hà Nội',
        'Truyện tranh, thiếu nhi, sách tham khảo.',
        4.6,
        76,
      ),
      shop(
        's5',
        'u5',
        'Dev Shelf',
        'Sách lập trình, giáo trình CNTT.',
        4.7,
        51,
      ),
      shop('s6', 'u6', 'Hà Thành Xưa', 'Sách ngoại văn và kỹ năng.', 4.4, 19),
    ]) {
      shops[s.id] = s;
    }

    // ── danh mục ──
    categories.addAll(const [
      Category(id: 'c1', name: 'Văn học Việt Nam'),
      Category(id: 'c2', name: 'Văn học nước ngoài'),
      Category(id: 'c3', name: 'Giáo trình đại học'),
      Category(id: 'c31', name: 'Công nghệ thông tin', parentId: 'c3'),
      Category(id: 'c5', name: 'Kỹ năng sống'),
      Category(id: 'c6', name: 'Thiếu nhi'),
      Category(id: 'c7', name: 'Sách hiếm & cổ'),
    ]);

    // ── tin bán ── (mỗi ấn bản bìa của mỗi cuốn trong fake_catalog.dart là một tin, rải đều cho các shop)
    const shopIds = ['s1', 's3', 's4', 's5', 's6'];
    const conditions = [
      ConditionGrade.veryGood,
      ConditionGrade.good,
      ConditionGrade.likeNew,
      ConditionGrade.good,
      ConditionGrade.veryGood,
    ];
    final ownerByShop = {for (final e in _shopOwner.entries) e.key: e.value};
    var i = 0;
    for (final b in _catalog) {
      for (var e = 0; e < b.eds.length; e++) {
        i++;
        final shopId = shopIds[(shopIds.indexOf(b.shop) + e) % shopIds.length];
        final listing = Listing(
          id: 'l$i',
          book: _catBook(b.slug, e, id: 'b$i', cond: conditions[i % 5]),
          shop: _summary(shops[shopId]!),
          price: (b.price * (1 + 0.15 * e) / 1000).round() * 1000,
          stock: i % 7 == 0 ? 2 : 1,
          status: ListingStatus.active,
          createdAt: now.subtract(Duration(hours: i * 7)),
        );
        _listings[listing.id] = _ListingRow(listing, ownerByShop[shopId]!);
      }
    }
    // Một tin chờ duyệt (cho Admin).
    _listings['l90'] = _ListingRow(
      Listing(
        id: 'l90',
        book: _catBook('bi-vo', 1, id: 'b90'),
        shop: _summary(shops['s4']!),
        price: 30000,
        stock: 1,
        status: ListingStatus.pendingReview,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      'u4',
    );

    // ── địa chỉ ──
    addresses['u1'] = [
      const Address(
        id: 'a1',
        receiver: 'Nguyễn Minh Anh',
        phone: '0901234567',
        province: 'TP. Hồ Chí Minh',
        district: 'TP. Thủ Đức',
        ward: 'P. Long Thạnh Mỹ',
        detail: 'Đại học FPT, Lô E2a-7, Đường D1, Khu Công nghệ cao',
        isDefault: true,
      ),
      const Address(
        id: 'a2',
        receiver: 'Nguyễn Minh Anh',
        phone: '0901234567',
        province: 'Hà Nội',
        district: 'Q. Cầu Giấy',
        ward: 'P. Dịch Vọng',
        detail: '12 Trần Thái Tông',
        isDefault: false,
      ),
    ];
    addresses['u2'] = [
      const Address(
        id: 'a3',
        receiver: 'Huỳnh Đăng Khoa',
        phone: '0907654321',
        province: 'TP. Hồ Chí Minh',
        district: 'Quận 10',
        ward: 'P. 12',
        detail: '268 Lý Thường Kiệt',
        isDefault: true,
      ),
    ];

    // ── ví ──
    _ledger(
      'u1',
      WalletTxnType.topUp,
      availableDelta: 3000000,
      note: 'Nạp qua VNPay',
      refType: 'PAYMENT',
    );
    _ledger(
      'u2',
      WalletTxnType.topUp,
      availableDelta: 1500000,
      note: 'Nạp qua VNPay',
      refType: 'PAYMENT',
    );
    _ledger(
      'u3',
      WalletTxnType.saleRelease,
      availableDelta: 820000,
      note: 'Tiền bán đơn RB1001',
    );

    // ── đơn mẫu ──
    _seedOrders(now);

    // ── ký gửi + phiên đấu giá ──
    _seedConsignments(now);
    _seedAuctions(now);
    _seedAdminData(now);

    // ── thông báo ──
    notify(
      'u1',
      NotificationType.order,
      'Đơn RB1002 đang giao',
      'Shop Gác Xép đã giao cho đơn vị vận chuyển.',
      '/account/orders',
    );
    notify(
      'u1',
      NotificationType.auctionReminder,
      'Phiên tối nay đã bắt đầu',
      'Sách văn học Việt Nam bản xưa đang diễn ra. Vào phòng để trả giá.',
      '/auctions',
    );
    notify(
      'u1',
      NotificationType.consignment,
      'Kết quả kiểm định',
      'Cuốn "Vang Bóng Một Thời" đã đạt kiểm định. Xem đề xuất giá.',
      '/account/seller/consignments',
    );
    _changed('all');
  }

  ShopSummary _summary(Shop s) => ShopSummary(
    id: s.id,
    name: s.name,
    ratingAvg: s.ratingAvg,
    ratingCount: s.ratingCount,
    avatarUrl: s.avatarUrl,
  );

  /// Dữ liệu mẫu cho nhật ký Admin, rút tiền có biên lai và một lời mời mua lần hai.
  void _seedAdminData(DateTime now) {
    final done = Withdrawal(
      id: 'wd-seed1',
      amount: 500000,
      status: WithdrawalStatus.completed,
      createdAt: now.subtract(const Duration(days: 3)),
      userName: 'Nguyễn Minh Anh',
      receipt: WithdrawalReceipt(
        senderName: 'CTY TNHH REBOOK',
        transferredAt: now.subtract(const Duration(days: 2, hours: 4)),
        amount: 500000,
        proofImageUrl: '',
      ),
    );
    final pending = Withdrawal(
      id: 'wd-seed2',
      amount: 300000,
      status: WithdrawalStatus.pending,
      createdAt: now.subtract(const Duration(hours: 6)),
      userName: 'Nguyễn Minh Anh',
    );
    withdrawals.addAll([pending, done]);
    _withdrawalOwner['wd-seed1'] = 'u1';
    _withdrawalOwner['wd-seed2'] = 'u1';

    ActivityLog log(
      AdminAction a,
      Duration ago, {
      String? target,
      String? note,
    }) => ActivityLog(
      id: _id('log'),
      adminName: 'Admin ReBook',
      action: a,
      createdAt: now.subtract(ago),
      target: target,
      note: note,
    );
    activityLogs.addAll([
      log(
        AdminAction.withdrawalCompleted,
        const Duration(days: 2, hours: 4),
        target: 'Nguyễn Minh Anh',
        note: '500000',
      ),
      log(
        AdminAction.userUnlocked,
        const Duration(days: 4),
        target: 'sachcuhn@rebook.vn',
      ),
      log(AdminAction.configChanged, const Duration(days: 6)),
      log(
        AdminAction.listingApproved,
        const Duration(days: 7),
        target: 'Dế Mèn Phiêu Lưu Ký',
      ),
    ]);

    // Lời mời mua lần hai cho người dùng demo (u2): lô bị bỏ thanh toán, giá ≥ giá sàn, hạn 24h.
    final row = _lots.values
        .where((r) => r.lot.status != LotStatus.live)
        .firstOrNull;
    if (row != null) {
      final offer = SecondChanceOffer(
        id: 'so-seed1',
        lotId: row.lot.id,
        lotNumber: row.lot.lotNumber,
        bookTitle: row.lot.book.title,
        amount: row.reserve,
        expiresAt: now.add(const Duration(hours: 20)),
        status: SecondChanceStatus.pending,
        coverUrl: row.lot.book.coverUrl,
      );
      secondChances['u2'] = [offer];
      notify(
        'u2',
        NotificationType.auctionWon,
        'Lời mời mua lần hai · Lô ${row.lot.lotNumber}',
        'Người thắng đã bỏ thanh toán. Bạn có 24 giờ để mua với giá bạn đã trả.',
        '/auctions/account/offers',
      );
    }
  }

  void _seedOrders(DateTime now) {
    Order make({
      required String code,
      required String buyer,
      required String listingId,
      required OrderStatus status,
      required Duration ago,
      PaymentMethod method = PaymentMethod.wallet,
      bool reviewed = false,
    }) {
      final row = _listings[listingId]!;
      final book = row.listing.book;
      final id = 'o$code';
      final history = <OrderStatusChange>[
        OrderStatusChange(
          to: OrderStatus.pendingConfirm,
          at: now.subtract(ago),
        ),
      ];
      const flow = [
        OrderStatus.preparing,
        OrderStatus.shipping,
        OrderStatus.delivered,
        OrderStatus.completed,
      ];
      for (var k = 0; k < flow.length && flow.indexOf(status) >= k; k++) {
        history.add(
          OrderStatusChange(
            from: history.last.to,
            to: flow[k],
            at: now.subtract(ago).add(Duration(hours: 6 * (k + 1))),
          ),
        );
      }
      final order = Order(
        id: id,
        code: code,
        type: OrderType.normal,
        status: status,
        items: [
          OrderItem(
            id: '${id}i',
            title: book.title,
            unitPrice: row.listing.price,
            quantity: 1,
            listingId: listingId,
            imageUrl: book.coverUrl,
          ),
        ],
        subtotal: row.listing.price,
        shippingFee: 25000,
        buyerPremium: 0,
        depositApplied: 0,
        total: row.listing.price + 25000,
        createdAt: now.subtract(ago),
        history: history,
        canReview: status == OrderStatus.completed && !reviewed,
        shop: row.listing.shop,
        buyerName: _accountById(buyer).user.fullName,
        paymentMethod: method,
        address: addresses[buyer]!.first,
        trackingCode: status.index >= OrderStatus.shipping.index
            ? 'GHN${code}VN'
            : null,
        complaintDeadline: status == OrderStatus.delivered
            ? now.add(const Duration(days: 2))
            : null,
        confirmDeadline: status == OrderStatus.pendingConfirm
            ? now.add(const Duration(hours: 20))
            : null,
      );
      orders[id] = order;
      _orderBuyer[id] = buyer;
      return order;
    }

    make(
      code: 'RB1001',
      buyer: 'u1',
      listingId: 'l5',
      status: OrderStatus.completed,
      ago: const Duration(days: 9),
    );
    make(
      code: 'RB1002',
      buyer: 'u1',
      listingId: 'l2',
      status: OrderStatus.shipping,
      ago: const Duration(days: 2),
    );
    make(
      code: 'RB1003',
      buyer: 'u1',
      listingId: 'l3',
      status: OrderStatus.delivered,
      ago: const Duration(days: 4),
    );
    make(
      code: 'RB1004',
      buyer: 'u2',
      listingId: 'l18',
      status: OrderStatus.pendingConfirm,
      ago: const Duration(hours: 3),
      method: PaymentMethod.cod,
    );
    make(
      code: 'RB1005',
      buyer: 'u2',
      listingId: 'l14',
      status: OrderStatus.preparing,
      ago: const Duration(days: 1),
    );
  }
}
