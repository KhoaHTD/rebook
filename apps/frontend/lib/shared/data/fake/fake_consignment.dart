part of 'fake_store.dart';

/// Ký gửi, kiểm định và kho (SRS 6.1, 6.2, 6.6).
extension FakeConsignment on FakeStore {
  void _seedConsignments(DateTime now) {
    Consignment c(
      String id,
      String seller,
      String slug,
      int ed,
      int expected,
      String story,
      ConsignmentStatus status, {
      Inspection? inspection,
      DateTime? appointmentAt,
      String? code,
      String? warehouseCode,
      int ageDays = 3,
    }) => Consignment(
      id: id,
      sellerId: seller,
      sellerName: _accountById(seller).user.fullName,
      book: _catBook(slug, ed, id: 'cb$id'),
      expectedPrice: expected,
      story: story,
      status: status,
      createdAt: now.subtract(Duration(days: ageDays)),
      inspection: inspection,
      appointmentAt: appointmentAt,
      appointmentCode: code,
      appointmentExpiresAt: code == null
          ? null
          : now.add(const Duration(days: 5)),
      warehouseCode: warehouseCode,
      receivedAt: warehouseCode == null
          ? null
          : now.subtract(const Duration(days: 1)),
    );

    for (final x in [
      c(
        'k1',
        'u1',
        'bi-vo',
        0,
        600000,
        'Bản in 1962, bìa giấy dó.',
        ConsignmentStatus.submitted,
        ageDays: 1,
      ),
      c(
        'k2',
        'u1',
        'so-do',
        1,
        1500000,
        'Bản Mai Lĩnh 1938, thiếu bìa sau.',
        ConsignmentStatus.preApproved,
        ageDays: 2,
      ),
      c(
        'k3',
        'u1',
        'vang-bong',
        0,
        900000,
        'Bản in lần đầu Tân Dân 1940.',
        ConsignmentStatus.inspected,
        warehouseCode: 'KHO-A-12',
        inspection: Inspection(
          id: 'i3',
          result: InspectionResult.pass,
          checklist: const InspectionChecklist(hasNotes: true, coverOk: false),
          condition: ConditionGrade.good,
          conditionReport: 'Đủ trang, đúng ấn bản Tân Dân 1940. Bìa trước rách góc, có ghi chú bút chì ở trang lót.',
          staffImageUrls: const [],
          sellerDecision: SellerDecision.pending,
          createdAt: now.subtract(const Duration(hours: 5)),
          estimateLow: 800000,
          estimateHigh: 1200000,
          proposedStart: 500000,
          proposedReserve: 750000,
        ),
      ),
      c(
        'k4',
        'u3',
        'truyen-kieu',
        0,
        2000000,
        'Bản Tản Đà thư cục 1925.',
        ConsignmentStatus.submitted,
        ageDays: 0,
      ),
      c(
        'k5',
        'u4',
        'tho-tho',
        0,
        700000,
        'Bìa cổ điển, bản in 1942.',
        ConsignmentStatus.appointmentBooked,
        appointmentAt: DateTime(now.year, now.month, now.day, 14),
        code: 'KG-4521',
      ),
      c(
        'k6',
        'u6',
        'leu-chong',
        1,
        450000,
        'Bìa hiện đại, có chữ ký.',
        ConsignmentStatus.received,
        warehouseCode: 'KHO-B-03',
      ),
    ]) {
      consignments[x.id] = x;
      if (x.warehouseCode != null) {
        warehouse[x.id] = WarehouseItem(
          id: 'w${x.id}',
          consignmentId: x.id,
          bookTitle: x.book.title,
          sellerName: x.sellerName,
          shelfCode: x.warehouseCode!,
          status: WarehouseStatus.inStock,
          checkedInAt: x.receivedAt!,
        );
      }
    }
  }

  List<Consignment> myConsignments() =>
      consignments.values.where((c) => c.sellerId == _uid).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Consignment consignment(String id) =>
      consignments[id] ?? fail(ErrorCodes.notFound, 404);

  Consignment createConsignment(BookDraft d, int expectedPrice, String story) {
    final c = Consignment(
      id: _id('k'),
      sellerId: _uid,
      sellerName: me.fullName,
      book: Book(
        id: _id('cb'),
        title: d.title,
        author: d.author,
        condition: d.condition,
        images: [for (final u in d.imageUrls) BookImage(url: u)],
        publisher: d.publisher,
        publishYear: d.publishYear,
        description: d.description,
      ),
      expectedPrice: expectedPrice,
      story: story,
      status: ConsignmentStatus.submitted,
      createdAt: DateTime.now(),
    );
    consignments[c.id] = c;
    _changed('consignments');
    // Quy tắc tự động: giá mong muốn dưới ngưỡng thì từ chối ngay (SRS 6.1).
    if (expectedPrice < consignmentMinExpectedPrice) {
      return preReview(
        c.id,
        approve: false,
        reason: 'Giá mong muốn dưới 300.000đ — phù hợp bán giá cố định hơn.',
      );
    }
    return c;
  }

  /// Sơ duyệt online trong 48h; giá mong muốn dưới 300.000đ thì từ chối (SRS 6.1).
  Consignment preReview(String id, {required bool approve, String? reason}) {
    final c = consignment(id);
    if (c.status != ConsignmentStatus.submitted) {
      fail(ErrorCodes.invalidTransition);
    }
    final next = c.copyWith(
      status: approve
          ? ConsignmentStatus.preApproved
          : ConsignmentStatus.preRejected,
      rejectReason: approve ? null : reason,
      approvedAt: approve ? DateTime.now() : null,
    );
    consignments[id] = next;
    notify(
      c.sellerId!,
      NotificationType.consignment,
      approve ? 'Yêu cầu ký gửi được duyệt' : 'Yêu cầu ký gửi bị từ chối',
      approve
          ? 'Hãy đặt lịch mang "${c.book.title}" tới kho trong 7 ngày.'
          : (reason ?? ''),
      '/account/seller/consignments',
    );
    _changed('consignments');
    return next;
  }

  List<AppointmentSlot> appointmentSlots() {
    final now = DateTime.now();
    final taken = consignments.values
        .map((c) => c.appointmentAt)
        .whereType<DateTime>()
        .toSet();
    return [
      for (var d = 1; d <= 6; d++)
        for (final h in const [9, 10, 11, 14, 15, 16])
          () {
            final t = DateTime(now.year, now.month, now.day + d, h);
            return AppointmentSlot(
              startAt: t,
              available: !taken.contains(t) && t.weekday != DateTime.sunday,
            );
          }(),
    ];
  }

  Consignment bookAppointment(String id, DateTime at) {
    final c = consignment(id);
    if (c.status != ConsignmentStatus.preApproved) {
      fail(ErrorCodes.invalidTransition);
    }
    final next = c.copyWith(
      status: ConsignmentStatus.appointmentBooked,
      appointmentAt: at,
      appointmentCode: 'KG-${1000 + rnd.nextInt(8999)}',
      appointmentExpiresAt: (c.approvedAt ?? DateTime.now()).add(
        const Duration(days: 7),
      ),
    );
    consignments[id] = next;
    _changed('consignments');
    return next;
  }

  List<Consignment> staffConsignments({ConsignmentStatus? status}) =>
      consignments.values
          .where((c) => status == null || c.status == status)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Consignment> appointments() =>
      consignments.values
          .where((c) => c.status == ConsignmentStatus.appointmentBooked)
          .toList()
        ..sort((a, b) => a.appointmentAt!.compareTo(b.appointmentAt!));

  /// Quét / nhập mã lịch hẹn, lập biên nhận, gán mã kho (SRS 6.1).
  Consignment checkIn(String code, List<String> receiptImages, String? shelf) {
    final c = consignments.values.firstWhere(
      (x) =>
          x.appointmentCode?.toUpperCase() == code.trim().toUpperCase() &&
          x.status == ConsignmentStatus.appointmentBooked,
      orElse: () => fail(ErrorCodes.notFound, 404),
    );
    final shelfCode = (shelf == null || shelf.isEmpty)
        ? 'KHO-${String.fromCharCode(65 + rnd.nextInt(4))}-${10 + rnd.nextInt(80)}'
        : shelf;
    final next = c.copyWith(
      status: ConsignmentStatus.received,
      receivedAt: DateTime.now(),
      warehouseCode: shelfCode,
    );
    consignments[c.id] = next;
    warehouse[c.id] = WarehouseItem(
      id: 'w${c.id}',
      consignmentId: c.id,
      bookTitle: c.book.title,
      sellerName: c.sellerName,
      shelfCode: shelfCode,
      status: WarehouseStatus.inStock,
      checkedInAt: DateTime.now(),
    );
    notify(
      c.sellerId!,
      NotificationType.consignment,
      'Kho đã nhận sách',
      '"${c.book.title}" đã vào kho, đang chờ kiểm định.',
      '/account/seller/consignments',
    );
    _changed('consignments');
    return next;
  }

  Consignment submitInspection(String id, InspectionDraft d) {
    final c = consignment(id);
    if (c.status != ConsignmentStatus.received) {
      fail(ErrorCodes.invalidTransition);
    }
    final pass = d.result == InspectionResult.pass;
    final next = c.copyWith(
      status: pass
          ? ConsignmentStatus.inspected
          : ConsignmentStatus.inspectionFailed,
      inspection: Inspection(
        id: _id('i'),
        result: d.result,
        checklist: d.checklist,
        condition: d.condition,
        conditionReport: d.conditionReport,
        staffImageUrls: d.staffImageUrls,
        sellerDecision: SellerDecision.pending,
        createdAt: DateTime.now(),
        estimateLow: d.estimateLow,
        estimateHigh: d.estimateHigh,
        proposedStart: d.proposedStart,
        proposedReserve: d.proposedReserve,
      ),
    );
    consignments[id] = next;
    notify(
      c.sellerId!,
      NotificationType.consignment,
      pass ? 'Kết quả kiểm định: đạt' : 'Kết quả kiểm định: không đạt',
      pass
          ? 'Xem đề xuất giá cho "${c.book.title}".'
          : 'Hãy đến kho nhận lại sách trong 14 ngày.',
      '/account/seller/consignments',
    );
    _changed('consignments');
    return next;
  }

  /// Người bán chấp nhận / đề nghị giá sàn khác / rút sách (SRS 6.2).
  Consignment decide(
    String id,
    SellerDecision decision, {
    int? counterReserve,
  }) {
    final c = consignment(id);
    final ins = c.inspection;
    if (c.status != ConsignmentStatus.inspected || ins == null) {
      fail(ErrorCodes.invalidTransition);
    }
    switch (decision) {
      case SellerDecision.withdraw:
        consignments[id] = c.copyWith(
          status: ConsignmentStatus.withdrawn,
          inspection: ins.copyWith(sellerDecision: decision),
        );
        warehouse[id] = warehouse[id]!.copyWith(
          status: WarehouseStatus.returned,
          checkedOutAt: DateTime.now(),
        );
      case SellerDecision.counter:
        // Giá sàn không được vượt mức thấp của ước tính (SRS 6.2) — sàn chấp nhận nếu hợp lệ.
        final reserve = counterReserve ?? ins.proposedReserve ?? 0;
        if (ins.estimateLow != null && reserve > ins.estimateLow!) {
          fail(ErrorCodes.invalidTransition, 400);
        }
        _acceptAsLot(
          c,
          ins.copyWith(sellerDecision: decision, counterReserve: reserve),
          reserve,
        );
      case SellerDecision.accept:
        _acceptAsLot(
          c,
          ins.copyWith(sellerDecision: decision),
          ins.proposedReserve ?? 0,
        );
      case SellerDecision.pending:
        break;
    }
    _changed('consignments');
    return consignments[id]!;
  }

  void _acceptAsLot(Consignment c, Inspection ins, int reserve) {
    final lotId = _id('lot');
    _lots[lotId] = _LotRow(
      Lot(
        id: lotId,
        sessionId: '',
        lotNumber: 0,
        book: c.book.copyWith(condition: ins.condition),
        estimateLow: ins.estimateLow ?? 0,
        estimateHigh: ins.estimateHigh ?? 0,
        startPrice: ins.proposedStart ?? 0,
        currentPrice: ins.proposedStart ?? 0,
        bidCount: 0,
        status: LotStatus.ready,
        watched: false,
        story: c.story,
        conditionReport: ins.conditionReport,
        signature: ins.checklist.signature,
      ),
      reserve: reserve,
      consignmentId: c.id,
      sellerId: c.sellerId!,
    );
    consignments[c.id] = c.copyWith(
      status: ConsignmentStatus.accepted,
      inspection: ins,
      lotId: lotId,
      lotStatus: LotStatus.ready,
    );
  }

  /// Lô không bán được: phiên sau / bán giá cố định / nhận lại (SRS 6.6).
  Consignment chooseAfterUnsold(
    String id,
    UnsoldChoice choice, {
    int? newReserve,
    int? fixedPrice,
  }) {
    final c = consignment(id);
    final row = c.lotId == null ? null : _lots[c.lotId];
    if (row == null || row.lot.status != LotStatus.unsold) {
      fail(ErrorCodes.invalidTransition);
    }
    switch (choice) {
      case UnsoldChoice.nextSession:
        row.reserve = newReserve ?? row.reserve;
        row.lot = row.lot.copyWith(
          status: LotStatus.ready,
          sessionId: '',
          bidCount: 0,
          currentPrice: row.lot.startPrice,
          outcome: null,
        );
      case UnsoldChoice.fixedPrice:
        row.lot = row.lot.copyWith(status: LotStatus.returned);
        final shopId =
            _shopOwner.entries
                .where((e) => e.value == c.sellerId)
                .firstOrNull
                ?.key ??
            shops.keys.first;
        final l = Listing(
          id: _id('l'),
          book: row.lot.book,
          shop: _summary(shops[shopId]!),
          price: fixedPrice ?? row.lot.startPrice,
          stock: 1,
          status: ListingStatus.active,
          createdAt: DateTime.now(),
        );
        _listings[l.id] = _ListingRow(l, c.sellerId!);
      case UnsoldChoice.returnToSeller:
        row.lot = row.lot.copyWith(status: LotStatus.returned);
        warehouse[id] = warehouse[id]!.copyWith(
          status: WarehouseStatus.returned,
          checkedOutAt: DateTime.now(),
        );
    }
    consignments[id] = c.copyWith(lotStatus: row.lot.status);
    _changed('consignments');
    return consignments[id]!;
  }

  List<WarehouseItem> warehouseItems({WarehouseStatus? status}) {
    return warehouse.values
        .map((w) {
          final c = consignments[w.consignmentId];
          final lot = c?.lotId == null ? null : _lots[c!.lotId]?.lot;
          return w.copyWith(lotStatus: lot?.status);
        })
        .where((w) => status == null || w.status == status)
        .toList()
      ..sort((a, b) => b.checkedInAt.compareTo(a.checkedInAt));
  }

  WarehouseItem updateWarehouse(
    String id, {
    String? shelf,
    WarehouseStatus? status,
  }) {
    final key = warehouse.entries
        .firstWhere(
          (e) => e.value.id == id,
          orElse: () => fail(ErrorCodes.notFound, 404),
        )
        .key;
    final w = warehouse[key]!;
    warehouse[key] = w.copyWith(
      shelfCode: shelf ?? w.shelfCode,
      status: status ?? w.status,
      checkedOutAt:
          status == WarehouseStatus.shipped ||
              status == WarehouseStatus.returned
          ? DateTime.now()
          : w.checkedOutAt,
    );
    _changed('warehouse');
    return warehouse[key]!;
  }

  /// Đơn AUCTION kho cần giao (SRS 6.6).
  List<Order> auctionOrders({OrderStatus? status}) => orders.values
      .where(
        (o) =>
            o.type == OrderType.auction &&
            o.status != OrderStatus.pendingPayment,
      )
      .where((o) => status == null || o.status == status)
      .toList();

  Order advanceAuctionOrder(String id, String? tracking) {
    final o = order(id);
    final next = switch (o.status) {
      OrderStatus.preparing => OrderStatus.shipping,
      OrderStatus.shipping => OrderStatus.delivered,
      _ => fail(ErrorCodes.invalidTransition),
    };
    _transition(
      id,
      next,
      note: next == OrderStatus.shipping
          ? 'Kho đã xuất, đang giao'
          : 'Giao thành công',
    );
    if (next == OrderStatus.shipping) {
      orders[id] = orders[id]!.copyWith(
        trackingCode: tracking ?? 'GHN${_seq}VN',
      );
      final lotId = o.items.first.lotId;
      final c = consignments.values.where((x) => x.lotId == lotId).firstOrNull;
      if (c != null && warehouse[c.id] != null) {
        warehouse[c.id] = warehouse[c.id]!.copyWith(
          status: WarehouseStatus.shipped,
          checkedOutAt: DateTime.now(),
        );
      }
    } else {
      orders[id] = orders[id]!.copyWith(
        complaintDeadline: DateTime.now().add(const Duration(days: 3)),
      );
    }
    return orders[id]!;
  }
}
