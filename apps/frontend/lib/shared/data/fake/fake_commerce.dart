part of 'fake_store.dart';

/// Mua bán giá cố định, ví và thanh toán (SRS mục 4, 8).
extension FakeCommerce on FakeStore {
  // ───────────────────────── catalog ─────────────────────────

  Paged<Listing> searchListings(ListingQuery q, {int page = 0, int size = 20}) {
    final text = q.q?.trim().toLowerCase() ?? '';
    final childCats = q.categoryId == null
        ? <String>{}
        : {
            q.categoryId!,
            ...categories
                .where((c) => c.parentId == q.categoryId)
                .map((c) => c.id),
          };
    var list = _listings.values
        .map((r) => r.listing)
        .where((l) => l.status == ListingStatus.active)
        .where(
          (l) =>
              text.isEmpty ||
              l.book.title.toLowerCase().contains(text) ||
              l.book.author.toLowerCase().contains(text),
        )
        .where(
          (l) => childCats.isEmpty || childCats.contains(l.book.categoryId),
        )
        .where(
          (l) =>
              q.author == null ||
              l.book.author.toLowerCase().contains(q.author!.toLowerCase()),
        )
        .where((l) => q.condition == null || l.book.condition == q.condition)
        .where((l) => q.minPrice == null || l.price >= q.minPrice!)
        .where((l) => q.maxPrice == null || l.price <= q.maxPrice!)
        .where((l) => q.shopId == null || l.shop.id == q.shopId)
        .toList();
    list.sort(
      (a, b) => switch (q.sort) {
        ListingSort.priceAsc => a.price.compareTo(b.price),
        ListingSort.priceDesc => b.price.compareTo(a.price),
        ListingSort.newest ||
        ListingSort.relevance => b.createdAt.compareTo(a.createdAt),
      },
    );
    final total = list.length;
    list = list.skip(page * size).take(size).toList();
    return Paged(items: list, page: page, size: size, total: total);
  }

  Listing listing(String id) =>
      (_listings[id] ?? fail(ErrorCodes.notFound, 404)).listing;

  Shop shop(String id) {
    final s = shops[id] ?? fail(ErrorCodes.notFound, 404);
    final active = _listings.values
        .where(
          (r) =>
              r.listing.shop.id == id &&
              r.listing.status == ListingStatus.active,
        )
        .length;
    return s.copyWith(activeListings: active);
  }

  List<Review> shopReviews(String shopId) =>
      List.of(reviews[shopId] ?? const []);

  ({List<ShopSummary> shops, List<Listing> trending, List<Listing> fresh})
  homeFeed() {
    final active = _listings.values
        .map((r) => r.listing)
        .where((l) => l.status == ListingStatus.active)
        .toList();
    final fresh = [...active]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final trending = [...active]
      ..sort((a, b) => b.shop.ratingAvg.compareTo(a.shop.ratingAvg));
    return (
      shops: shops.values.map(_summary).toList(),
      trending: trending.take(8).toList(),
      fresh: fresh.take(10).toList(),
    );
  }

  // ───────────────────────── seller listings ─────────────────────────

  Shop? myShop() {
    final entry = _shopOwner.entries.where((e) => e.value == _uid).firstOrNull;
    return entry == null ? null : shop(entry.key);
  }

  Shop openShop(ShopDraft d) {
    if (myShop() != null) fail(ErrorCodes.invalidTransition);
    final id = _id('s');
    _shopOwner[id] = _uid;
    shops[id] = Shop(
      id: id,
      userId: _uid,
      name: d.name,
      description: d.description,
      pickupAddress: d.pickupAddress,
      ratingAvg: 0,
      ratingCount: 0,
      createdAt: DateTime.now(),
    );
    final acc = _accountById(_uid);
    acc.user = acc.user.copyWith(hasShop: true);
    return shops[id]!;
  }

  Shop updateShop(ShopDraft d) {
    final s = myShop() ?? fail(ErrorCodes.notFound, 404);
    shops[s.id] = s.copyWith(
      name: d.name,
      description: d.description,
      pickupAddress: d.pickupAddress,
    );
    return shops[s.id]!;
  }

  Paged<Listing> myListings({ListingStatus? status}) {
    final s = myShop() ?? fail(ErrorCodes.notFound, 404);
    final list =
        _listings.values
            .map((r) => r.listing)
            .where(
              (l) =>
                  l.shop.id == s.id && (status == null || l.status == status),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Paged(items: list, page: 0, size: list.length, total: list.length);
  }

  Listing saveListing(String? id, BookDraft d, int price, int stock) {
    final s = myShop() ?? fail(ErrorCodes.notFound, 404);
    final cat = categories.where((c) => c.id == d.categoryId).firstOrNull;
    final book = Book(
      id: id == null ? _id('b') : listing(id).book.id,
      title: d.title,
      author: d.author,
      condition: d.condition,
      images: [for (final u in d.imageUrls) BookImage(url: u)],
      publisher: d.publisher,
      publishYear: d.publishYear,
      isbn: d.isbn,
      language: d.language,
      pages: d.pages,
      categoryId: d.categoryId,
      categoryName: cat?.name,
      description: d.description,
      weightGram: d.weightGram,
    );
    // Shop uy tín (≥ 4.5 sao, ≥ 20 đánh giá) được duyệt tự động (SRS 4.1).
    final trusted = s.ratingAvg >= 4.5 && s.ratingCount >= 20;
    final existing = id == null ? null : listing(id);
    final next = Listing(
      id: id ?? _id('l'),
      book: book,
      shop: _summary(s),
      price: price,
      stock: stock,
      status: stock == 0
          ? ListingStatus.outOfStock
          : trusted
          ? ListingStatus.active
          : ListingStatus.pendingReview,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    _listings[next.id] = _ListingRow(next, _uid);
    _changed('listings');
    return next;
  }

  Listing setListingVisible(String id, {required bool visible}) {
    final row = _listings[id] ?? fail(ErrorCodes.notFound, 404);
    final l = row.listing;
    row.listing = l.copyWith(
      status: visible
          ? (l.stock > 0 ? ListingStatus.active : ListingStatus.outOfStock)
          : ListingStatus.hidden,
    );
    _changed('listings');
    return row.listing;
  }

  void deleteListing(String id) {
    _listings.remove(id);
    _changed('listings');
  }

  List<Listing> listingsByStatus(ListingStatus? status) => _listings.values
      .map((r) => r.listing)
      .where((l) => status == null || l.status == status)
      .toList();

  /// Ghi một dòng vào nhật ký hoạt động của Admin (SRS 8.1).
  void _log(AdminAction action, {String? target, String? note}) {
    activityLogs.insert(
      0,
      ActivityLog(
        id: _id('log'),
        adminName: currentUserId == null ? '—' : me.fullName,
        action: action,
        createdAt: DateTime.now(),
        target: target,
        note: note,
      ),
    );
  }

  List<ActivityLog> allActivityLogs() => List.of(activityLogs);

  Listing reviewListing(String id, {required bool approve, String? reason}) {
    final row = _listings[id] ?? fail(ErrorCodes.notFound, 404);
    row.listing = row.listing.copyWith(
      status: approve ? ListingStatus.active : ListingStatus.rejected,
      rejectReason: approve ? null : reason,
    );
    notify(
      row.shopOwnerId,
      NotificationType.system,
      approve ? 'Tin đăng đã được duyệt' : 'Tin đăng bị từ chối',
      '"${row.listing.book.title}"${approve ? ' đang được bán.' : ': ${reason ?? ''}'}',
      '/account/seller/listings',
    );
    _log(
      approve ? AdminAction.listingApproved : AdminAction.listingRejected,
      target: row.listing.book.title,
      note: approve ? null : reason,
    );
    _changed('listings');
    return row.listing;
  }

  SellerStats sellerStats() {
    final s = myShop() ?? fail(ErrorCodes.notFound, 404);
    final mine = orders.values.where((o) => o.shop?.id == s.id).toList();
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month);
    final completed = mine.where((o) => o.status == OrderStatus.completed);
    return SellerStats(
      revenueTotal: completed.fold(0, (n, o) => n + o.subtotal),
      revenueThisMonth: completed
          .where((o) => o.createdAt.isAfter(monthStart))
          .fold(0, (n, o) => n + o.subtotal),
      pendingBalance: walletOf(_uid).held,
      ordersToConfirm: mine
          .where((o) => o.status == OrderStatus.pendingConfirm)
          .length,
      ordersShipping: mine
          .where(
            (o) =>
                o.status == OrderStatus.shipping ||
                o.status == OrderStatus.preparing,
          )
          .length,
      ordersCompleted: completed.length,
      activeListings: myListings(status: ListingStatus.active).total,
      ratingAvg: s.ratingAvg,
    );
  }

  // ───────────────────────── cart ─────────────────────────

  /// Phí ship theo bảng cố định (SRS 11.1): nội tỉnh 20k, ngoại tỉnh 35k, +5k mỗi 500g quá 500g.
  int shippingFee({required String? province, required int weightGram}) {
    final base = province == null || province.contains('Hồ Chí Minh')
        ? 20000
        : 35000;
    final extra = weightGram <= 500
        ? 0
        : ((weightGram - 500) / 500).ceil() * 5000;
    return base + extra;
  }

  Cart cart({String? addressId}) {
    final items = _cart[_uid] ?? const [];
    final address = myAddresses()
        .where((a) => a.id == addressId || (addressId == null && a.isDefault))
        .firstOrNull;
    final byShop = <String, List<CartItem>>{};
    for (final it in items) {
      final fresh = it.copyWith(listing: listing(it.listing.id));
      byShop.putIfAbsent(fresh.listing.shop.id, () => []).add(fresh);
    }
    final groups = [
      for (final e in byShop.entries)
        () {
          final subtotal = e.value.fold(
            0,
            (n, i) => n + i.listing.price * i.quantity,
          );
          final weight = e.value.fold(
            0,
            (n, i) => n + (i.listing.book.weightGram ?? 400) * i.quantity,
          );
          return CartGroup(
            shop: e.value.first.listing.shop,
            items: e.value,
            subtotal: subtotal,
            shippingFee: shippingFee(
              province: address?.province,
              weightGram: weight,
            ),
          );
        }(),
    ];
    final subtotal = groups.fold(0, (n, g) => n + g.subtotal);
    final ship = groups.fold(0, (n, g) => n + g.shippingFee);
    return Cart(
      groups: groups,
      subtotal: subtotal,
      shippingTotal: ship,
      total: subtotal + ship,
    );
  }

  Cart addToCart(String listingId, int quantity) {
    final l = listing(listingId);
    if (!l.purchasable) fail(ErrorCodes.outOfStock);
    if (_shopOwner[l.shop.id] == _uid) fail(ErrorCodes.ownListing);
    final list = _cart.putIfAbsent(_uid, () => []);
    final idx = list.indexWhere((i) => i.listing.id == listingId);
    if (idx >= 0) {
      final q = (list[idx].quantity + quantity).clamp(1, l.stock);
      list[idx] = list[idx].copyWith(quantity: q);
    } else {
      list.add(
        CartItem(
          id: _id('ci'),
          listing: l,
          quantity: quantity.clamp(1, l.stock),
        ),
      );
    }
    _changed('cart');
    return cart();
  }

  Cart updateCartItem(String id, int quantity) {
    final list = _cart[_uid] ?? [];
    final idx = list.indexWhere((i) => i.id == id);
    if (idx < 0) fail(ErrorCodes.notFound, 404);
    if (quantity <= 0) {
      list.removeAt(idx);
    } else {
      list[idx] = list[idx].copyWith(
        quantity: quantity.clamp(1, list[idx].listing.stock),
      );
    }
    _changed('cart');
    return cart();
  }

  // ───────────────────────── checkout & payment ─────────────────────────

  /// Tách mỗi shop một đơn, giữ hàng ngay (SRS 4.2).
  CheckoutResult checkout({
    required String addressId,
    required PaymentMethod method,
    List<String>? itemIds,
  }) {
    final address = myAddresses().firstWhere(
      (a) => a.id == addressId,
      orElse: () => fail(ErrorCodes.notFound, 404),
    );
    final c = cart(addressId: addressId);
    final now = DateTime.now();
    final created = <Order>[];
    final chosen = <String>{};
    for (final g in c.groups) {
      final items = g.items
          .where((i) => itemIds == null || itemIds.contains(i.id))
          .toList();
      if (items.isEmpty) continue;
      // Giữ hàng: trừ tồn kho ngay, chống hai người cùng mua cuốn duy nhất.
      for (final it in items) {
        final row = _listings[it.listing.id]!;
        if (row.listing.stock < it.quantity ||
            row.listing.status != ListingStatus.active) {
          fail(ErrorCodes.outOfStock);
        }
      }
      for (final it in items) {
        final row = _listings[it.listing.id]!;
        final stock = row.listing.stock - it.quantity;
        row.listing = row.listing.copyWith(
          stock: stock,
          status: stock == 0 ? ListingStatus.outOfStock : row.listing.status,
        );
        chosen.add(it.id);
      }
      final subtotal = items.fold(
        0,
        (n, i) => n + i.listing.price * i.quantity,
      );
      final weight = items.fold(
        0,
        (n, i) => n + (i.listing.book.weightGram ?? 400) * i.quantity,
      );
      final ship = shippingFee(province: address.province, weightGram: weight);
      final online = method != PaymentMethod.cod;
      final code = 'RB${++_seq}';
      final order = Order(
        id: 'o$code',
        code: code,
        type: OrderType.normal,
        status: online
            ? OrderStatus.pendingPayment
            : OrderStatus.pendingConfirm,
        items: [
          for (final i in items)
            OrderItem(
              id: _id('oi'),
              title: i.listing.book.title,
              unitPrice: i.listing.price,
              quantity: i.quantity,
              listingId: i.listing.id,
              imageUrl: i.listing.book.coverUrl,
            ),
        ],
        subtotal: subtotal,
        shippingFee: ship,
        buyerPremium: 0,
        depositApplied: 0,
        total: subtotal + ship,
        createdAt: now,
        history: [
          OrderStatusChange(
            to: online
                ? OrderStatus.pendingPayment
                : OrderStatus.pendingConfirm,
            at: now,
          ),
        ],
        canReview: false,
        shop: g.shop,
        buyerName: me.fullName,
        paymentMethod: method,
        address: address,
        paymentDeadline: online
            ? now.add(Duration(minutes: config.orderPaymentTimeoutMin))
            : null,
        confirmDeadline: online ? null : now.add(const Duration(hours: 24)),
      );
      orders[order.id] = order;
      _orderBuyer[order.id] = _uid;
      created.add(order);
    }
    if (created.isEmpty) fail(ErrorCodes.invalidTransition, 400);
    _cart[_uid]?.removeWhere((i) => chosen.contains(i.id));
    _changed('cart');
    _changed('orders');

    final total = created.fold(0, (n, o) => n + o.total);
    if (method == PaymentMethod.wallet) {
      _payFromWallet(_uid, created.map((o) => o.id).toList(), total);
      return CheckoutResult(orders: created.map((o) => orders[o.id]!).toList());
    }
    if (method == PaymentMethod.vnpay) {
      final p = _createPayment(
        _uid,
        total,
        orderIds: created.map((o) => o.id).toList(),
      );
      return CheckoutResult(orders: created, payment: p);
    }
    for (final o in created) {
      notify(
        _shopOwner[o.shop!.id]!,
        NotificationType.order,
        'Đơn mới ${o.code}',
        'Xác nhận trong 24 giờ.',
        '/account/seller/orders',
      );
    }
    return CheckoutResult(orders: created);
  }

  void _payFromWallet(String userId, List<String> orderIds, int total) {
    if (walletOf(userId).available < total) {
      fail(ErrorCodes.insufficientBalance);
    }
    _ledger(
      userId,
      WalletTxnType.payment,
      availableDelta: -total,
      note: 'Thanh toán ${orderIds.length} đơn',
      refType: 'ORDER',
    );
    for (final id in orderIds) {
      _markPaid(id);
    }
  }

  Payment _createPayment(
    String userId,
    int amount, {
    List<String> orderIds = const [],
    bool topUp = false,
  }) {
    final p = Payment(
      id: _id('pay'),
      amount: amount,
      status: PaymentStatus.pending,
      paymentUrl: 'mock://vnpay-sandbox',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    payments[p.id] = p;
    _paymentTarget[p.id] = (userId: userId, orderIds: orderIds, topUp: topUp);
    return p;
  }

  /// Giả lập cổng VNPay gọi IPN về backend. Lưu mã giao dịch để không cộng trùng (SRS 8.1).
  Payment completePayment(String paymentId, {bool success = true}) {
    final p = payments[paymentId] ?? fail(ErrorCodes.notFound, 404);
    if (p.status != PaymentStatus.pending) return p; // IPN đến 2 lần: bỏ qua.
    final target = _paymentTarget[paymentId]!;
    final done = p.copyWith(
      status: success ? PaymentStatus.success : PaymentStatus.failed,
    );
    payments[paymentId] = done;
    if (!success) return done;
    if (target.topUp) {
      _ledger(
        target.userId,
        WalletTxnType.topUp,
        availableDelta: p.amount,
        note: 'Nạp qua VNPay',
        refType: 'PAYMENT',
        refId: p.id,
      );
      notify(
        target.userId,
        NotificationType.wallet,
        'Nạp tiền thành công',
        'Ví đã được cộng tiền.',
        '/account/wallet',
      );
    } else {
      for (final id in target.orderIds) {
        _markPaid(id);
      }
    }
    return done;
  }

  Payment payment(String id) => payments[id] ?? fail(ErrorCodes.notFound, 404);

  void _markPaid(String orderId) {
    final o = orders[orderId]!;
    final next = o.type == OrderType.auction
        ? OrderStatus.preparing
        : OrderStatus.pendingConfirm;
    _transition(orderId, next, note: 'Đã thanh toán');
    _orderSellerPaid[orderId] = true;
    if (o.type == OrderType.auction) _applyDeposit(orderId);
    if (o.type == OrderType.normal) {
      // Tiền bán hàng chờ hoàn tất đơn: khoá trong ví người bán (SALE_PENDING).
      final seller = _shopOwner[o.shop!.id]!;
      _ledger(
        seller,
        WalletTxnType.salePending,
        heldDelta: o.subtotal,
        note: 'Đơn ${o.code} chờ hoàn tất',
        refType: 'ORDER',
        refId: o.id,
      );
      orders[orderId] = orders[orderId]!.copyWith(
        confirmDeadline: DateTime.now().add(const Duration(hours: 24)),
      );
      notify(
        seller,
        NotificationType.order,
        'Đơn mới ${o.code}',
        'Xác nhận trong 24 giờ.',
        '/account/seller/orders',
      );
    }
  }

  CheckoutResult payOrder(
    String orderId,
    PaymentMethod method, {
    String? addressId,
    bool pickup = false,
  }) {
    final o = orders[orderId] ?? fail(ErrorCodes.notFound, 404);
    if (o.status != OrderStatus.pendingPayment) {
      fail(ErrorCodes.invalidTransition);
    }
    var order = o;
    if (o.type == OrderType.auction) {
      final address = addressId == null
          ? null
          : myAddresses().firstWhere((a) => a.id == addressId);
      final ship = pickup || address == null ? 0 : 30000;
      order = o.copyWith(
        address: address,
        pickupAtWarehouse: pickup,
        shippingFee: ship,
        total: o.subtotal + o.buyerPremium + ship - o.depositApplied,
      );
      orders[orderId] = order;
    }
    if (method == PaymentMethod.wallet) {
      _payFromWallet(_uid, [orderId], order.total);
      return CheckoutResult(orders: [orders[orderId]!]);
    }
    final p = _createPayment(_uid, order.total, orderIds: [orderId]);
    return CheckoutResult(orders: [order], payment: p);
  }

  Payment topUp(int amount) => _createPayment(_uid, amount, topUp: true);

  // ───────────────────────── orders ─────────────────────────

  void _transition(String orderId, OrderStatus to, {String? note}) {
    final o = orders[orderId]!;
    if (o.status != to && !canTransition(o.status, to)) {
      fail(ErrorCodes.invalidTransition);
    }
    orders[orderId] = o.copyWith(
      status: to,
      history: [
        ...o.history,
        OrderStatusChange(
          from: o.status,
          to: to,
          at: DateTime.now(),
          note: note,
        ),
      ],
      canReview:
          to == OrderStatus.completed &&
          o.review == null &&
          o.type == OrderType.normal,
    );
    final buyer = _orderBuyer[orderId];
    if (buyer != null && buyer != currentUserId) {
      notify(
        buyer,
        NotificationType.order,
        'Đơn ${o.code}: cập nhật',
        'Trạng thái mới của đơn hàng.',
        '/account/orders',
      );
    }
    _changed('orders');
  }

  Paged<Order> myOrders({OrderStatus? status, OrderType? type}) {
    final list =
        orders.values
            .where((o) => _orderBuyer[o.id] == _uid)
            .where((o) => status == null || o.status == status)
            .where((o) => type == null || o.type == type)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Paged(items: list, page: 0, size: list.length, total: list.length);
  }

  Order order(String id) {
    _escalateOverdueReturns();
    return orders[id] ?? fail(ErrorCodes.notFound, 404);
  }

  /// Quá hạn shop / kho chưa trả lời yêu cầu trả hàng → tự chuyển Admin phân xử, tiền vẫn do sàn giữ (SRS 4.4).
  void _escalateOverdueReturns() {
    final now = DateTime.now();
    for (final o in List.of(orders.values)) {
      final rr = o.returnRequest;
      if (rr == null ||
          rr.status != ReturnStatus.pending ||
          rr.respondBy == null ||
          now.isBefore(rr.respondBy!)) {
        continue;
      }
      orders[o.id] = o.copyWith(
        returnRequest: rr.copyWith(
          status: ReturnStatus.escalated,
          resolution: 'Quá hạn trả lời, chuyển Admin phân xử',
        ),
      );
      _changed('orders');
    }
  }

  void _refundOrder(Order o, String note) {
    final buyer = _orderBuyer[o.id]!;
    final paid = _orderSellerPaid[o.id] ?? false;
    if (paid) {
      _ledger(
        buyer,
        WalletTxnType.refund,
        availableDelta: o.total,
        note: note,
        refType: 'ORDER',
        refId: o.id,
      );
      if (o.type == OrderType.normal) {
        _ledger(
          _shopOwner[o.shop!.id]!,
          WalletTxnType.salePending,
          heldDelta: -o.subtotal,
          note: 'Hoàn đơn ${o.code}',
        );
      }
      _orderSellerPaid[o.id] = false;
    }
    // Hoàn tồn kho.
    for (final it in o.items) {
      final row = it.listingId == null ? null : _listings[it.listingId];
      if (row != null) {
        row.listing = row.listing.copyWith(
          stock: row.listing.stock + it.quantity,
          status: row.listing.status == ListingStatus.outOfStock
              ? ListingStatus.active
              : row.listing.status,
        );
      }
    }
  }

  Order cancelByBuyer(String id, String reason) {
    final o = order(id);
    if (o.buyerCanCancelDirectly) {
      _transition(id, OrderStatus.cancelled, note: reason);
      _refundOrder(o, 'Hoàn tiền đơn ${o.code} đã hủy');
    } else if (o.buyerCanRequestCancel) {
      orders[id] = o.copyWith(cancelRequested: true);
      notify(
        _shopOwner[o.shop!.id]!,
        NotificationType.order,
        'Yêu cầu hủy ${o.code}',
        reason,
        '/account/seller/orders',
      );
      _changed('orders');
    } else {
      fail(ErrorCodes.invalidTransition);
    }
    return orders[id]!;
  }

  Order confirmReceived(String id) {
    final o = order(id);
    final rr = o.returnRequest;
    // Bấm "Đã nhận hàng" khi đang yêu cầu trả hàng = rút yêu cầu: đóng yêu cầu, đơn hoàn tất (SRS 4.4).
    final withdrawing =
        o.status == OrderStatus.returnRequested &&
        rr != null &&
        (rr.status == ReturnStatus.pending ||
            rr.status == ReturnStatus.escalated);
    _transition(
      id,
      OrderStatus.completed,
      note: withdrawing
          ? 'Người mua rút yêu cầu trả hàng và xác nhận đã nhận'
          : 'Người mua đã nhận hàng',
    );
    if (withdrawing) {
      orders[id] = orders[id]!.copyWith(
        returnRequest: rr.copyWith(status: ReturnStatus.withdrawn),
      );
    }
    _releaseSale(o);
    return orders[id]!;
  }

  /// Hoàn tất → sàn trừ phí, cộng tiền vào ví người bán (SRS 4.3, 8.2).
  void _releaseSale(Order o) {
    if (o.type != OrderType.normal) {
      _payConsignors(o);
      return;
    }
    final seller = _shopOwner[o.shop!.id]!;
    final fee = fees.fixedPriceFee(o.subtotal);
    if (_orderSellerPaid[o.id] ?? false) {
      _ledger(
        seller,
        WalletTxnType.saleRelease,
        heldDelta: -o.subtotal,
        note: 'Đơn ${o.code} hoàn tất',
      );
      _ledger(
        seller,
        WalletTxnType.saleRelease,
        availableDelta: o.subtotal,
        note: 'Tiền bán ${o.code}',
        refType: 'ORDER',
        refId: o.id,
      );
    } else {
      // COD: tiền thu hộ về sàn rồi mới trả người bán.
      _ledger(
        seller,
        WalletTxnType.saleRelease,
        availableDelta: o.subtotal,
        note: 'Tiền bán ${o.code} (COD)',
        refType: 'ORDER',
        refId: o.id,
      );
    }
    _ledger(
      seller,
      WalletTxnType.fee,
      availableDelta: -fee,
      note: 'Phí sàn 5% đơn ${o.code}',
      refType: 'ORDER',
      refId: o.id,
    );
  }

  Order requestReturn(String id, String reason, List<String> images) {
    final o = order(id);
    _transition(id, OrderStatus.returnRequested, note: reason);
    orders[id] = orders[id]!.copyWith(
      returnRequest: ReturnRequest(
        id: _id('rt'),
        reason: reason,
        imageUrls: images,
        status: ReturnStatus.pending,
        respondBy: DateTime.now().add(
          Duration(days: config.returnResponseDays),
        ),
      ),
    );
    notify(
      _shopOwner[o.shop!.id]!,
      NotificationType.order,
      'Yêu cầu trả hàng ${o.code}',
      reason,
      '/account/seller/orders',
    );
    return orders[id]!;
  }

  Order review(String id, int rating, String? comment) {
    final o = order(id);
    if (!o.canReview) fail(ErrorCodes.invalidTransition);
    final r = Review(
      id: _id('rv'),
      orderId: id,
      reviewerName: me.fullName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    reviews.putIfAbsent(o.shop!.id, () => []).insert(0, r);
    final s = shops[o.shop!.id]!;
    final count = s.ratingCount + 1;
    shops[s.id] = s.copyWith(
      ratingCount: count,
      ratingAvg: ((s.ratingAvg * s.ratingCount) + rating) / count,
    );
    orders[id] = o.copyWith(review: r, canReview: false);
    _changed('orders');
    return orders[id]!;
  }

  // ───────────────────────── seller orders ─────────────────────────

  Paged<Order> shopOrders({OrderStatus? status}) {
    final s = myShop() ?? fail(ErrorCodes.notFound, 404);
    final list =
        orders.values
            .where(
              (o) =>
                  o.shop?.id == s.id && o.status != OrderStatus.pendingPayment,
            )
            .where((o) => status == null || o.status == status)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Paged(items: list, page: 0, size: list.length, total: list.length);
  }

  Order sellerConfirm(String id) {
    _transition(id, OrderStatus.preparing, note: 'Shop đã xác nhận');
    return orders[id]!;
  }

  Order sellerShip(String id, String? tracking) {
    _transition(
      id,
      OrderStatus.shipping,
      note: 'Đã giao cho đơn vị vận chuyển',
    );
    orders[id] = orders[id]!.copyWith(trackingCode: tracking ?? 'GHN${_seq}VN');
    return orders[id]!;
  }

  Order markDelivered(String id) {
    _transition(id, OrderStatus.delivered, note: 'Giao thành công');
    orders[id] = orders[id]!.copyWith(
      complaintDeadline: DateTime.now().add(const Duration(days: 3)),
    );
    return orders[id]!;
  }

  Order sellerCancel(String id, String reason) {
    final o = order(id);
    _transition(id, OrderStatus.cancelled, note: reason);
    _refundOrder(o, 'Shop hủy đơn ${o.code}');
    return orders[id]!;
  }

  /// Shop đồng ý / từ chối trả hàng; từ chối thì chuyển Admin phân xử (SRS 4.4).
  Order decideReturn(String id, {required bool accept, String? note}) {
    final o = order(id);
    final rr = o.returnRequest ?? fail(ErrorCodes.invalidTransition);
    if (accept) {
      _transition(
        id,
        OrderStatus.returned,
        note: note ?? 'Shop đồng ý trả hàng',
      );
      orders[id] = orders[id]!.copyWith(
        returnRequest: rr.copyWith(
          status: ReturnStatus.accepted,
          resolution: note,
        ),
      );
      _refundOrder(o, 'Hoàn tiền trả hàng ${o.code}');
    } else {
      orders[id] = o.copyWith(
        returnRequest: rr.copyWith(
          status: ReturnStatus.escalated,
          resolution: note,
        ),
      );
      _changed('orders');
    }
    return orders[id]!;
  }

  List<Order> disputes() {
    _escalateOverdueReturns();
    return orders.values
        .where((o) => o.returnRequest?.status == ReturnStatus.escalated)
        .toList();
  }

  Order resolveDispute(String id, {required bool refund, String? note}) {
    final o = order(id);
    if (refund) {
      _transition(
        id,
        OrderStatus.returned,
        note: note ?? 'Admin phân xử: hoàn tiền',
      );
      _refundOrder(o, 'Admin hoàn tiền ${o.code}');
    } else {
      _transition(
        id,
        OrderStatus.completed,
        note: note ?? 'Admin phân xử: từ chối trả hàng',
      );
      _releaseSale(o);
    }
    orders[id] = orders[id]!.copyWith(
      returnRequest: o.returnRequest!.copyWith(
        status: refund
            ? ReturnStatus.resolvedRefund
            : ReturnStatus.resolvedNoRefund,
        resolution: note,
      ),
    );
    return orders[id]!;
  }

  // ───────────────────────── wallet ─────────────────────────

  List<WalletTxn> myTxns() => List.of(txns[_uid] ?? const []);

  Withdrawal requestWithdrawal(int amount) {
    if (walletOf(_uid).available < amount) fail(ErrorCodes.insufficientBalance);
    _ledger(
      _uid,
      WalletTxnType.withdraw,
      availableDelta: -amount,
      note: 'Yêu cầu rút tiền',
    );
    final w = Withdrawal(
      id: _id('wd'),
      amount: amount,
      status: WithdrawalStatus.pending,
      createdAt: DateTime.now(),
      userName: me.fullName,
    );
    withdrawals.insert(0, w);
    _withdrawalOwner[w.id] = _uid;
    return w;
  }

  List<Withdrawal> myWithdrawals() =>
      withdrawals.where((w) => _withdrawalOwner[w.id] == _uid).toList();

  /// Admin duyệt rút tiền: phải nhập biên lai, số tiền đúng số yêu cầu (SRS 8.1).
  Withdrawal completeWithdrawal(String id, WithdrawalReceipt receipt) {
    final idx = withdrawals.indexWhere((w) => w.id == id);
    if (idx < 0) fail(ErrorCodes.notFound, 404);
    if (withdrawals[idx].status != WithdrawalStatus.pending) {
      fail(ErrorCodes.invalidTransition);
    }
    if (receipt.amount != withdrawals[idx].amount) {
      fail(ErrorCodes.receiptMismatch, 422);
    }
    withdrawals[idx] = withdrawals[idx].copyWith(
      status: WithdrawalStatus.completed,
      receipt: receipt,
    );
    _log(
      AdminAction.withdrawalCompleted,
      target: withdrawals[idx].userName,
      note: '${receipt.amount}',
    );
    notify(
      _withdrawalOwner[id]!,
      NotificationType.wallet,
      'Đã chuyển tiền',
      'Yêu cầu rút tiền đã được xử lý.',
      '/account/wallet',
    );
    return withdrawals[idx];
  }

  // ───────────────────────── notifications ─────────────────────────

  List<AppNotification> myNotifications() =>
      List.of(notifications[_uid] ?? const []);

  void markRead(String? id) {
    final list = notifications[_uid];
    if (list == null) return;
    for (var k = 0; k < list.length; k++) {
      if (id == null || list[k].id == id) {
        list[k] = list[k].copyWith(isRead: true);
      }
    }
    _changed('notifications');
  }

  // ───────────────────────── admin ─────────────────────────

  Category saveCategory(String? id, String name, String? parentId) {
    final c = Category(id: id ?? _id('c'), name: name, parentId: parentId);
    final idx = categories.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      categories[idx] = c;
    } else {
      categories.add(c);
    }
    return c;
  }

  void deleteCategory(String id) =>
      categories.removeWhere((c) => c.id == id || c.parentId == id);

  SystemConfig updateConfig(SystemConfig c) {
    config = c;
    fees = FeeConfig(
      fixedPriceFeePercent: c.fixedPriceFeePercent,
      buyerPremiumPercent: c.buyerPremiumPercent,
      sellerCommissionPercent: c.sellerCommissionPercent,
      depositLimitMultiplier: c.depositLimitMultiplier,
      storageFeePerDay: c.storageFeePerDay,
      storageFreeDays: c.storageFreeDays,
    );
    _log(AdminAction.configChanged);
    return config;
  }

  Dashboard dashboard() {
    final done = orders.values.where((o) => o.status == OrderStatus.completed);
    final closedLots = _lots.values.where((r) => r.lot.outcome != null);
    final sold = closedLots
        .where((r) => r.lot.outcome == LotOutcome.sold)
        .length;
    return Dashboard(
      revenueTotal: done.fold(0, (n, o) => n + o.total),
      platformFees: done.fold(
        0,
        (n, o) => n + fees.fixedPriceFee(o.subtotal) + o.buyerPremium,
      ),
      orderCount: orders.length,
      lotSoldRate: closedLots.isEmpty ? 0 : sold / closedLots.length,
      activeUsers: _accounts.length,
      pendingListings: listingsByStatus(ListingStatus.pendingReview).length,
      pendingConsignments: consignments.values
          .where((c) => c.status == ConsignmentStatus.submitted)
          .length,
    );
  }
}
