part of 'fake_store.dart';

typedef _B = ({
  String title,
  String author,
  String cat,
  ConditionGrade cond,
  int price,
  String shop,
  int year,
  String publisher,
  int pages,
  String desc,
});

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
      Category(id: 'c32', name: 'Kinh tế', parentId: 'c3'),
      Category(id: 'c33', name: 'Ngoại ngữ', parentId: 'c3'),
      Category(id: 'c4', name: 'Truyện tranh'),
      Category(id: 'c5', name: 'Kỹ năng sống'),
      Category(id: 'c6', name: 'Thiếu nhi'),
      Category(id: 'c7', name: 'Sách hiếm & cổ'),
    ]);

    // ── tin bán ──
    const books = <_B>[
      (
        title: 'Mắt Biếc',
        author: 'Nguyễn Nhật Ánh',
        cat: 'c1',
        cond: ConditionGrade.likeNew,
        price: 65000,
        shop: 's1',
        year: 2019,
        publisher: 'NXB Trẻ',
        pages: 300,
        desc: 'Đọc một lần, bìa còn bóng, có bookmark gốc.',
      ),
      (
        title: 'Số Đỏ',
        author: 'Vũ Trọng Phụng',
        cat: 'c1',
        cond: ConditionGrade.good,
        price: 60000,
        shop: 's3',
        year: 2005,
        publisher: 'NXB Văn học',
        pages: 280,
        desc: 'Có ghi chú bút chì vài chương đầu.',
      ),
      (
        title: 'Nhà Giả Kim',
        author: 'Paulo Coelho',
        cat: 'c2',
        cond: ConditionGrade.veryGood,
        price: 55000,
        shop: 's6',
        year: 2020,
        publisher: 'NXB Hội Nhà Văn',
        pages: 228,
        desc: 'Gáy thẳng, không ghi chú.',
      ),
      (
        title: 'Dế Mèn Phiêu Lưu Ký',
        author: 'Tô Hoài',
        cat: 'c6',
        cond: ConditionGrade.veryGood,
        price: 45000,
        shop: 's4',
        year: 2015,
        publisher: 'NXB Kim Đồng',
        pages: 144,
        desc: 'Bản có tranh minh hoạ.',
      ),
      (
        title: 'Tôi Thấy Hoa Vàng Trên Cỏ Xanh',
        author: 'Nguyễn Nhật Ánh',
        cat: 'c1',
        cond: ConditionGrade.likeNew,
        price: 70000,
        shop: 's3',
        year: 2018,
        publisher: 'NXB Trẻ',
        pages: 378,
        desc: 'Như mới, bọc plastic.',
      ),
      (
        title: 'Rừng Na Uy',
        author: 'Haruki Murakami',
        cat: 'c2',
        cond: ConditionGrade.likeNew,
        price: 85000,
        shop: 's6',
        year: 2015,
        publisher: 'NXB Hội Nhà Văn',
        pages: 555,
        desc: 'Bản dịch Trịnh Lữ, đọc một lần.',
      ),
      (
        title: 'Hoàng Tử Bé',
        author: 'Antoine de Saint-Exupéry',
        cat: 'c2',
        cond: ConditionGrade.good,
        price: 40000,
        shop: 's4',
        year: 2012,
        publisher: 'NXB Hội Nhà Văn',
        pages: 112,
        desc: 'Ố vàng nhẹ ở mép giấy.',
      ),
      (
        title: 'Cho Tôi Xin Một Vé Đi Tuổi Thơ',
        author: 'Nguyễn Nhật Ánh',
        cat: 'c1',
        cond: ConditionGrade.veryGood,
        price: 50000,
        shop: 's1',
        year: 2017,
        publisher: 'NXB Trẻ',
        pages: 220,
        desc: 'Không ghi chú.',
      ),
      (
        title: 'Đắc Nhân Tâm',
        author: 'Dale Carnegie',
        cat: 'c5',
        cond: ConditionGrade.good,
        price: 40000,
        shop: 's6',
        year: 2016,
        publisher: 'NXB Tổng hợp TP.HCM',
        pages: 320,
        desc: 'Có gạch chân bút dạ vài trang.',
      ),
      (
        title: 'Clean Code',
        author: 'Robert C. Martin',
        cat: 'c31',
        cond: ConditionGrade.veryGood,
        price: 180000,
        shop: 's5',
        year: 2018,
        publisher: 'Prentice Hall',
        pages: 464,
        desc: 'Bản tiếng Anh, sạch.',
      ),
      (
        title: 'Lập trình Android cơ bản',
        author: 'Bộ môn CNPM',
        cat: 'c31',
        cond: ConditionGrade.good,
        price: 85000,
        shop: 's1',
        year: 2023,
        publisher: 'FPT University',
        pages: 260,
        desc: 'Giáo trình PRM393, có ghi chú của khoá trước.',
      ),
      (
        title: 'Cấu trúc dữ liệu và giải thuật',
        author: 'Lê Minh Hoàng',
        cat: 'c31',
        cond: ConditionGrade.veryGood,
        price: 95000,
        shop: 's5',
        year: 2019,
        publisher: 'NXB ĐHQG',
        pages: 410,
        desc: 'Gáy chắc, không thiếu trang.',
      ),
      (
        title: 'Kinh tế vĩ mô',
        author: 'N. Gregory Mankiw',
        cat: 'c32',
        cond: ConditionGrade.good,
        price: 120000,
        shop: 's6',
        year: 2014,
        publisher: 'Cengage',
        pages: 560,
        desc: 'Ghi chú bút chì nhiều chương.',
      ),
      (
        title: 'IELTS Cambridge 18',
        author: 'Cambridge',
        cat: 'c33',
        cond: ConditionGrade.likeNew,
        price: 110000,
        shop: 's1',
        year: 2023,
        publisher: 'Cambridge University Press',
        pages: 144,
        desc: 'Chưa viết vào.',
      ),
      (
        title: 'Tiếng Nhật Minna no Nihongo I',
        author: '3A Corporation',
        cat: 'c33',
        cond: ConditionGrade.good,
        price: 75000,
        shop: 's4',
        year: 2017,
        publisher: 'NXB Trẻ',
        pages: 300,
        desc: 'Có ghi chú từ vựng.',
      ),
      (
        title: 'Doraemon tập 12',
        author: 'Fujiko F. Fujio',
        cat: 'c4',
        cond: ConditionGrade.veryGood,
        price: 18000,
        shop: 's4',
        year: 2010,
        publisher: 'NXB Kim Đồng',
        pages: 190,
        desc: 'Bản cũ khổ nhỏ.',
      ),
      (
        title: 'Thám tử lừng danh Conan tập 1',
        author: 'Gosho Aoyama',
        cat: 'c4',
        cond: ConditionGrade.acceptable,
        price: 15000,
        shop: 's4',
        year: 2004,
        publisher: 'NXB Kim Đồng',
        pages: 180,
        desc: 'Bìa sờn, ruột đủ.',
      ),
      (
        title: 'Totto-chan bên cửa sổ',
        author: 'Kuroyanagi Tetsuko',
        cat: 'c6',
        cond: ConditionGrade.likeNew,
        price: 52000,
        shop: 's3',
        year: 2019,
        publisher: 'NXB Hội Nhà Văn',
        pages: 356,
        desc: 'Như mới.',
      ),
      (
        title: 'Nam Cao tuyển tập',
        author: 'Nam Cao',
        cat: 'c1',
        cond: ConditionGrade.good,
        price: 90000,
        shop: 's3',
        year: 2008,
        publisher: 'NXB Văn học',
        pages: 620,
        desc: 'Bìa cứng, ố nhẹ.',
      ),
      (
        title: 'Truyện Kiều',
        author: 'Nguyễn Du',
        cat: 'c1',
        cond: ConditionGrade.veryGood,
        price: 60000,
        shop: 's1',
        year: 2016,
        publisher: 'NXB Văn học',
        pages: 260,
        desc: 'Bản chú giải đầy đủ.',
      ),
      (
        title: 'Sapiens: Lược sử loài người',
        author: 'Yuval Noah Harari',
        cat: 'c2',
        cond: ConditionGrade.veryGood,
        price: 130000,
        shop: 's6',
        year: 2021,
        publisher: 'NXB Tri thức',
        pages: 560,
        desc: 'Không ghi chú.',
      ),
      (
        title: 'Nhà máy dữ liệu',
        author: 'Martin Kleppmann',
        cat: 'c31',
        cond: ConditionGrade.likeNew,
        price: 220000,
        shop: 's5',
        year: 2022,
        publisher: "O'Reilly",
        pages: 590,
        desc: 'Designing Data-Intensive Applications, bản dịch.',
      ),
      (
        title: 'Tuổi trẻ đáng giá bao nhiêu',
        author: 'Rosie Nguyễn',
        cat: 'c5',
        cond: ConditionGrade.good,
        price: 35000,
        shop: 's1',
        year: 2018,
        publisher: 'NXB Hội Nhà Văn',
        pages: 285,
        desc: 'Gấp góc vài trang.',
      ),
      (
        title: 'Chí Phèo',
        author: 'Nam Cao',
        cat: 'c1',
        cond: ConditionGrade.acceptable,
        price: 25000,
        shop: 's4',
        year: 2002,
        publisher: 'NXB Văn học',
        pages: 160,
        desc: 'Bìa bong, ruột đủ trang.',
      ),
    ];
    final ownerByShop = {for (final e in _shopOwner.entries) e.key: e.value};
    var i = 0;
    for (final b in books) {
      i++;
      final shopEntity = shops[b.shop]!;
      final cat = categories.firstWhere((c) => c.id == b.cat);
      final listing = Listing(
        id: 'l$i',
        book: Book(
          id: 'b$i',
          title: b.title,
          author: b.author,
          condition: b.cond,
          publisher: b.publisher,
          publishYear: b.year,
          pages: b.pages,
          language: 'Tiếng Việt',
          categoryId: cat.id,
          categoryName: cat.name,
          description: b.desc,
          weightGram: 200 + b.pages,
        ),
        shop: _summary(shopEntity),
        price: b.price,
        stock: i % 7 == 0 ? 2 : 1,
        status: ListingStatus.active,
        createdAt: now.subtract(Duration(hours: i * 7)),
      );
      _listings[listing.id] = _ListingRow(listing, ownerByShop[b.shop]!);
    }
    // Một tin chờ duyệt (cho Admin).
    _listings['l90'] = _ListingRow(
      Listing(
        id: 'l90',
        book: const Book(
          id: 'b90',
          title: 'Lão Hạc',
          author: 'Nam Cao',
          condition: ConditionGrade.good,
          categoryId: 'c1',
          categoryName: 'Văn học Việt Nam',
          description: 'Bản in 2010.',
        ),
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
      'Sách cổ Nam Bộ trước 1975 đang diễn ra. Vào phòng để trả giá.',
      '/auctions',
    );
    notify(
      'u1',
      NotificationType.consignment,
      'Kết quả kiểm định',
      'Cuốn "Vang bóng một thời" đã đạt kiểm định. Xem đề xuất giá.',
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
      listingId: 'l8',
      status: OrderStatus.pendingConfirm,
      ago: const Duration(hours: 3),
      method: PaymentMethod.cod,
    );
    make(
      code: 'RB1005',
      buyer: 'u2',
      listingId: 'l11',
      status: OrderStatus.preparing,
      ago: const Duration(days: 1),
    );
  }
}
