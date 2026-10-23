part of 'fake_store.dart';

typedef _LotSeed = ({
  String book,
  int ed,
  int start,
  int low,
  int high,
  int reserve,
  SignatureStatus sig,
  String story,
});

const _bots = ['#031', '#044', '#052', '#063', '#078', '#085'];

/// Đấu giá: phiên, lô, đăng ký + cọc, bộ máy chạy phiên (SRS 5, 6.3 – 6.6, 10.3).
extension FakeAuction on FakeStore {
  // ───────────────────────── seed ─────────────────────────

  void _seedAuctions(DateTime now) {
    const liveLots = <_LotSeed>[
      (
        book: 'tat-den',
        ed: 0,
        start: 400000,
        low: 700000,
        high: 1100000,
        reserve: 650000,
        sig: SignatureStatus.none,
        story: 'Bìa cổ điển, giấy ngà, gáy còn nguyên.',
      ),
      (
        book: 'leu-chong',
        ed: 0,
        start: 300000,
        low: 500000,
        high: 800000,
        reserve: 450000,
        sig: SignatureStatus.none,
        story: 'Bìa cổ điển, có dấu thư viện nhỏ.',
      ),
      (
        book: 'vang-bong',
        ed: 0,
        start: 350000,
        low: 600000,
        high: 900000,
        reserve: 550000,
        sig: SignatureStatus.none,
        story: 'Bìa cổ điển, tranh bìa gốc.',
      ),
      (
        book: 'tho-tho',
        ed: 0,
        start: 800000,
        low: 1200000,
        high: 2000000,
        reserve: 1100000,
        sig: SignatureStatus.unverified,
        story: 'Có chữ ký, chưa xác thực.',
      ),
      (
        book: 'truyen-kieu',
        ed: 0,
        start: 250000,
        low: 400000,
        high: 700000,
        reserve: 380000,
        sig: SignatureStatus.none,
        story: 'Bản chú giải, bìa minh hoạ cổ.',
      ),
      (
        book: 'bi-vo',
        ed: 0,
        start: 300000,
        low: 500000,
        high: 850000,
        reserve: 480000,
        sig: SignatureStatus.none,
        story: 'Bìa minh hoạ gốc.',
      ),
      (
        book: 'nam-phong',
        ed: 0,
        start: 400000,
        low: 650000,
        high: 1000000,
        reserve: 600000,
        sig: SignatureStatus.none,
        story: 'Số 1 năm 1917, bản in lại.',
      ),
      (
        book: 'tu-dien',
        ed: 0,
        start: 200000,
        low: 350000,
        high: 600000,
        reserve: 300000,
        sig: SignatureStatus.none,
        story: 'Từ điển Việt – Bồ – La của Alexandre de Rhodes, bản in lại.',
      ),
    ];
    final live = _makeSession(
      id: 'as1',
      title: 'Văn học Việt Nam bản xưa',
      description:
          'Văn học Việt Nam bản in cổ và bản in lại. Kiểm định bởi kho ReBook.',
      startAt: now.subtract(const Duration(seconds: 70)),
      deposit: 500000,
      minPeople: 5,
      status: SessionStatus.live,
      lots: liveLots,
      registered: 9,
    );
    // Lô 1 đã bán, lô 2 đang mở.
    final rows = _sessionRows(live.id);
    rows[0].lot = rows[0].lot.copyWith(
      status: LotStatus.sold,
      outcome: LotOutcome.sold,
      hammerPrice: 850000,
      currentPrice: 850000,
      bidCount: 9,
      leadingPaddle: '#044',
    );
    rows[1].lot = rows[1].lot.copyWith(
      status: LotStatus.live,
      endsAt: now.add(const Duration(seconds: 45)),
      currentPrice: 350000,
      bidCount: 2,
      leadingPaddle: '#052',
    );
    rows[1].bids.addAll([
      Bid(
        id: _id('bid'),
        lotId: rows[1].lot.id,
        paddleNumber: '#031',
        amount: 300000,
        createdAt: now.subtract(const Duration(seconds: 12)),
      ),
      Bid(
        id: _id('bid'),
        lotId: rows[1].lot.id,
        paddleNumber: '#052',
        amount: 350000,
        createdAt: now.subtract(const Duration(seconds: 5)),
      ),
    ]);
    sessions[live.id] = live.copyWith(currentLotId: rows[1].lot.id);
    _register('u1', live.id, 500000, paddle: '#027');

    const comics = <_LotSeed>[
      (
        book: 'rung-na-uy',
        ed: 1,
        start: 150000,
        low: 300000,
        high: 500000,
        reserve: 250000,
        sig: SignatureStatus.none,
        story: 'Bìa hiện đại, mới 95%.',
      ),
      (
        book: 'sapiens',
        ed: 1,
        start: 120000,
        low: 250000,
        high: 400000,
        reserve: 200000,
        sig: SignatureStatus.none,
        story: 'Bìa hiện đại, không ghi chú.',
      ),
      (
        book: 'nha-gia-kim',
        ed: 0,
        start: 100000,
        low: 200000,
        high: 350000,
        reserve: 150000,
        sig: SignatureStatus.unverified,
        story: 'Bìa gốc, gáy thẳng.',
      ),
      (
        book: 'dac-nhan-tam',
        ed: 0,
        start: 100000,
        low: 180000,
        high: 300000,
        reserve: 140000,
        sig: SignatureStatus.none,
        story: 'Bản bìa đỏ quen thuộc.',
      ),
      (
        book: 'clean-code',
        ed: 1,
        start: 90000,
        low: 150000,
        high: 260000,
        reserve: 120000,
        sig: SignatureStatus.none,
        story: 'Bìa hiện đại, sạch.',
      ),
    ];
    _makeSession(
      id: 'as2',
      title: 'Sách hay, bìa hiện đại',
      description: 'Các ấn bản bìa mới của những cuốn được yêu thích.',
      startAt: DateTime(now.year, now.month, now.day + 3, 20),
      deposit: 300000,
      minPeople: 5,
      status: SessionStatus.published,
      lots: comics,
      registered: 3,
    );

    const signed = <_LotSeed>[
      (
        book: 'so-do',
        ed: 2,
        start: 500000,
        low: 900000,
        high: 1500000,
        reserve: 800000,
        sig: SignatureStatus.verified,
        story: 'Ký tặng tại buổi giao lưu, có ảnh đối chiếu.',
      ),
      (
        book: 'truyen-kieu',
        ed: 1,
        start: 400000,
        low: 700000,
        high: 1100000,
        reserve: 600000,
        sig: SignatureStatus.verified,
        story: 'Bìa hiện đại, có chữ ký người dịch.',
      ),
      (
        book: 'de-men',
        ed: 1,
        start: 1200000,
        low: 2000000,
        high: 3500000,
        reserve: 1800000,
        sig: SignatureStatus.unverified,
        story: 'Bản minh hoạ cũ, chữ ký chưa xác thực.',
      ),
    ];
    _makeSession(
      id: 'as3',
      title: 'Ấn bản đặc biệt',
      startAt: DateTime(now.year, now.month, now.day + 1, 20),
      deposit: 1000000,
      minPeople: 4,
      status: SessionStatus.confirmed,
      lots: signed,
      registered: 6,
    ).let(
      (s) => sessions[s.id] = s.copyWith(
        registrationDeadline: now.subtract(const Duration(hours: 1)),
      ),
    );

    const old = <_LotSeed>[
      (
        book: 'giao-trinh-ctdl',
        ed: 0,
        start: 200000,
        low: 300000,
        high: 500000,
        reserve: 250000,
        sig: SignatureStatus.none,
        story: 'Giáo trình gốc, ít ghi chú.',
      ),
      (
        book: 'clean-code',
        ed: 0,
        start: 150000,
        low: 250000,
        high: 400000,
        reserve: 220000,
        sig: SignatureStatus.none,
        story: 'Bìa cổ điển, bản gốc tiếng Anh.',
      ),
      (
        book: 'nam-phong',
        ed: 1,
        start: 600000,
        low: 900000,
        high: 1400000,
        reserve: 1000000,
        sig: SignatureStatus.none,
        story: 'Bìa hiện đại, bản in lại.',
      ),
    ];
    final ended = _makeSession(
      id: 'as4',
      title: 'Giáo trình và tư liệu',
      startAt: now.subtract(const Duration(hours: 18)),
      deposit: 300000,
      minPeople: 5,
      status: SessionStatus.ended,
      lots: old,
      registered: 11,
    );
    final er = _sessionRows(ended.id);
    _register('u1', ended.id, 300000, paddle: '#014');
    er[0].lot = er[0].lot.copyWith(
      status: LotStatus.sold,
      outcome: LotOutcome.sold,
      hammerPrice: 450000,
      currentPrice: 450000,
      bidCount: 7,
      leadingPaddle: '#014',
    );
    er[0].leaderUserId = 'u1';
    er[1].lot = er[1].lot.copyWith(
      status: LotStatus.sold,
      outcome: LotOutcome.sold,
      hammerPrice: 300000,
      currentPrice: 300000,
      bidCount: 4,
      leadingPaddle: '#063',
    );
    er[2].lot = er[2].lot.copyWith(
      status: LotStatus.unsold,
      outcome: LotOutcome.belowReserve,
      currentPrice: 850000,
      bidCount: 3,
    );
    _createInvoice(ended, 'u1', [
      er[0],
    ], issuedAt: now.subtract(const Duration(hours: 18)));

    _makeSession(
      id: 'as5',
      title: 'Sách hiếm Việt Nam',
      description: 'Bản nháp — Admin đang xếp lô.',
      startAt: DateTime(now.year, now.month, now.day + 10, 20),
      deposit: 500000,
      minPeople: 5,
      status: SessionStatus.draft,
      lots: const [],
      registered: 0,
    );
    // Lô đã sẵn sàng, chờ xếp phiên (cho Admin).
    for (final s in const <_LotSeed>[
      (
        book: 'sapiens',
        ed: 0,
        start: 500000,
        low: 800000,
        high: 1300000,
        reserve: 700000,
        sig: SignatureStatus.none,
        story: 'Bìa cổ điển, mới 90%.',
      ),
      (
        book: 'tho-tho',
        ed: 2,
        start: 450000,
        low: 700000,
        high: 1000000,
        reserve: 650000,
        sig: SignatureStatus.none,
        story: 'Bìa hiện đại, bản đẹp.',
      ),
      (
        book: 'so-do',
        ed: 0,
        start: 700000,
        low: 1000000,
        high: 1800000,
        reserve: 950000,
        sig: SignatureStatus.none,
        story: 'Bìa gốc, đủ trang.',
      ),
    ]) {
      _lotFromSeed(
        s,
        sessionId: '',
        number: 0,
        status: LotStatus.ready,
        sellerId: 'u3',
      );
    }
  }

  AuctionSession _makeSession({
    required String id,
    required String title,
    required DateTime startAt,
    required int deposit,
    required int minPeople,
    required SessionStatus status,
    required List<_LotSeed> lots,
    required int registered,
    String? description,
  }) {
    final s = AuctionSession(
      id: id,
      title: title,
      description: description,
      startAt: startAt,
      registrationDeadline: startAt.subtract(const Duration(hours: 24)),
      minParticipants: minPeople,
      depositAmount: deposit,
      lotDurationSec: 60,
      softCloseSec: 15,
      status: status,
      lotCount: lots.length,
      registeredCount: registered,
      watcherCount: 20 + rnd.nextInt(90),
      coverImageUrl: lots.isEmpty
          ? null
          : _coverOf(lots.first.book, lots.first.ed),
    );
    sessions[id] = s;
    for (var k = 0; k < lots.length; k++) {
      _lotFromSeed(
        lots[k],
        sessionId: id,
        number: k + 1,
        status: status == SessionStatus.draft
            ? LotStatus.ready
            : LotStatus.scheduled,
        sellerId: ['u3', 'u4', 'u6'][k % 3],
      );
    }
    return s;
  }

  void _lotFromSeed(
    _LotSeed s, {
    required String sessionId,
    required int number,
    required LotStatus status,
    required String sellerId,
  }) {
    final id = _id('lot');
    final kid = _id('k');
    _lots[id] = _LotRow(
      Lot(
        id: id,
        sessionId: sessionId,
        lotNumber: number,
        book: _catBook(s.book, s.ed, id: _id('lb')),
        estimateLow: s.low,
        estimateHigh: s.high,
        startPrice: s.start,
        currentPrice: s.start,
        bidCount: 0,
        status: status,
        watched: false,
        story: s.story,
        conditionReport:
            'Đủ trang, đúng ấn bản. Bìa và gáy có dấu thời gian, không ẩm mốc.',
        signature: s.sig,
      ),
      reserve: s.reserve,
      consignmentId: kid,
      sellerId: sellerId,
    );
  }

  List<_LotRow> _sessionRows(String sessionId) =>
      _lots.values.where((r) => r.lot.sessionId == sessionId).toList()
        ..sort((a, b) => a.lot.lotNumber.compareTo(b.lot.lotNumber));

  Lot _view(_LotRow r) => r.lot.copyWith(
    watched: _watchers[r.lot.id]?.contains(currentUserId) ?? false,
  );

  Registration _register(
    String userId,
    String sessionId,
    int deposit, {
    String? paddle,
  }) {
    final s = sessions[sessionId]!;
    final reg = Registration(
      id: _id('reg'),
      sessionId: sessionId,
      sessionTitle: s.title,
      paddleNumber:
          paddle ?? '#${(100 + rnd.nextInt(899)).toString().padLeft(3, '0')}',
      depositAmount: deposit,
      bidLimit: fees.bidLimit(deposit),
      committedAmount: 0,
      status: RegistrationStatus.approved,
    );
    registrations[reg.id] = reg;
    _registrationOwner[reg.id] = userId;
    // Khoá cọc: available → held (DEPOSIT_HOLD) (SRS 8.3).
    final w = walletOf(userId);
    if (w.available < deposit) fail(ErrorCodes.insufficientBalance);
    _ledger(
      userId,
      WalletTxnType.depositHold,
      availableDelta: -deposit,
      heldDelta: deposit,
      note: 'Cọc phiên "${s.title}"',
      refType: 'SESSION',
      refId: sessionId,
    );
    return reg;
  }

  Registration? _regOf(String userId, String sessionId) => registrations.values
      .where(
        (r) => r.sessionId == sessionId && _registrationOwner[r.id] == userId,
      )
      .firstOrNull;

  // ───────────────────────── queries ─────────────────────────

  List<AuctionSession> listSessions({SessionStatus? status}) {
    _ensureEngine();
    return sessions.values
        .where((s) => s.status != SessionStatus.draft)
        .where((s) => status == null || s.status == status)
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  ({AuctionSession session, List<Lot> lots}) catalogue(String id) {
    final s = sessions[id] ?? fail(ErrorCodes.notFound, 404);
    return (session: s, lots: _sessionRows(id).map(_view).toList());
  }

  Lot lot(String id) => _view(_lots[id] ?? fail(ErrorCodes.notFound, 404));

  List<Bid> lotBids(String id) =>
      List.of((_lots[id] ?? fail(ErrorCodes.notFound, 404)).bids.reversed);

  Registration? myRegistration(String sessionId) => currentUserId == null
      ? null
      : _withCommitted(_regOf(currentUserId!, sessionId));

  List<Registration> myRegistrations() => registrations.values
      .where((r) => _registrationOwner[r.id] == currentUserId)
      .map((r) => _withCommitted(r)!)
      .toList();

  Registration? _withCommitted(Registration? r) {
    if (r == null) return null;
    final uid = _registrationOwner[r.id];
    final committed = _sessionRows(r.sessionId)
        .where(
          (x) =>
              x.leaderUserId == uid &&
              (x.lot.status == LotStatus.live ||
                  x.lot.status == LotStatus.sold),
        )
        .fold(0, (n, x) => n + x.lot.currentPrice);
    return r.copyWith(committedAmount: committed);
  }

  SessionState sessionState(String id) {
    _ensureEngine();
    final s = sessions[id] ?? fail(ErrorCodes.notFound, 404);
    final rows = _sessionRows(id);
    final current = s.currentLotId == null ? null : _lots[s.currentLotId];
    return SessionState(
      session: s,
      lots: rows.map(_view).toList(),
      serverTime: DateTime.now(),
      recentBids: current == null
          ? const []
          : current.bids.reversed.take(20).toList(),
      currentLot: current == null ? null : _view(current),
      myRegistration: myRegistration(id),
      viewerCount: s.watcherCount + rnd.nextInt(5),
    );
  }

  SessionResult sessionResults(String id) {
    final s = sessions[id] ?? fail(ErrorCodes.notFound, 404);
    final myReg = currentUserId == null ? null : _regOf(currentUserId!, id);
    return SessionResult(
      session: s,
      results: [
        for (final r in _sessionRows(id))
          if (r.lot.outcome != null)
            LotResult(
              lotId: r.lot.id,
              lotNumber: r.lot.lotNumber,
              title: r.lot.book.title,
              outcome: r.lot.outcome!,
              hammerPrice: r.lot.hammerPrice,
              winnerPaddle: r.lot.outcome == LotOutcome.sold
                  ? r.lot.leadingPaddle
                  : null,
              wonByMe:
                  myReg != null &&
                  r.lot.outcome == LotOutcome.sold &&
                  r.lot.leadingPaddle == myReg.paddleNumber,
            ),
      ],
    );
  }

  Stream<AuctionEvent> sessionEvents(String id) {
    _ensureEngine();
    return _sessionEvents
        .putIfAbsent(id, StreamController<AuctionEvent>.broadcast)
        .stream;
  }

  void _emit(String sessionId, AuctionEvent e) =>
      _sessionEvents[sessionId]?.add(e);

  // ───────────────────────── buyer actions ─────────────────────────

  Registration registerSession(String sessionId, int deposit) {
    final s = sessions[sessionId] ?? fail(ErrorCodes.notFound, 404);
    if (!me.phoneVerified) fail(ErrorCodes.notRegistered, 403);
    final banned = me.auctionBannedUntil;
    if (banned != null && banned.isAfter(DateTime.now())) {
      fail(ErrorCodes.auctionBanned, 403);
    }
    if (!s.acceptsRegistration) fail(ErrorCodes.registrationClosed);
    if (deposit < s.depositAmount) fail(ErrorCodes.bidTooLow, 400);
    final existing = _regOf(_uid, sessionId);
    if (existing != null) {
      // Cọc thêm để tăng hạn mức.
      final extra = deposit - existing.depositAmount;
      if (extra > 0) {
        if (walletOf(_uid).available < extra) {
          fail(ErrorCodes.insufficientBalance);
        }
        _ledger(
          _uid,
          WalletTxnType.depositHold,
          availableDelta: -extra,
          heldDelta: extra,
          note: 'Cọc thêm phiên "${s.title}"',
        );
        registrations[existing.id] = existing.copyWith(
          depositAmount: deposit,
          bidLimit: fees.bidLimit(deposit),
        );
      }
      return myRegistration(sessionId)!;
    }
    final reg = _register(_uid, sessionId, deposit);
    sessions[sessionId] = s.copyWith(registeredCount: s.registeredCount + 1);
    _changed('auctions');
    return reg;
  }

  Lot watch(String lotId, {required bool on}) {
    final set = _watchers.putIfAbsent(lotId, () => {});
    on ? set.add(_uid) : set.remove(_uid);
    return lot(lotId);
  }

  void setProxy(String lotId, int max) {
    final r = _lots[lotId] ?? fail(ErrorCodes.notFound, 404);
    if (_regOf(_uid, r.lot.sessionId) == null) {
      fail(ErrorCodes.notRegistered, 403);
    }
    _proxies[lotId] = (userId: _uid, max: max);
  }

  /// Kiểm tra một lượt trả giá phía server (SRS 6.5).
  Bid placeBid(String lotId, int amount) => _bid(lotId, amount, userId: _uid);

  Bid _bid(
    String lotId,
    int amount, {
    required String userId,
    String? botPaddle,
    bool auto = false,
  }) {
    final row = _lots[lotId] ?? fail(ErrorCodes.notFound, 404);
    final s = sessions[row.lot.sessionId]!;
    final now = DateTime.now();
    if (s.status != SessionStatus.live ||
        s.currentLotId != lotId ||
        row.lot.status != LotStatus.live ||
        !now.isBefore(row.lot.endsAt!)) {
      fail(ErrorCodes.lotClosed);
    }
    String paddle;
    if (botPaddle != null) {
      paddle = botPaddle;
    } else {
      final reg = _withCommitted(_regOf(userId, s.id));
      if (reg == null || reg.status != RegistrationStatus.approved) {
        fail(ErrorCodes.notRegistered, 403);
      }
      if (row.leaderUserId == userId) fail(ErrorCodes.alreadyLeading);
      if (reg.committedAmount + amount > reg.bidLimit) {
        fail(ErrorCodes.limitExceeded);
      }
      paddle = reg.paddleNumber;
    }
    final min = nextBidAmount(
      currentPrice: row.lot.currentPrice,
      bidCount: row.lot.bidCount,
      tiers: config.bidTiers,
    );
    if (amount < min) fail(ErrorCodes.priceChanged);

    final previousLeader = row.leaderUserId;
    final softClose = now.add(Duration(seconds: s.softCloseSec));
    final ends = row.lot.endsAt!.isBefore(softClose)
        ? softClose
        : row.lot.endsAt!;
    final bid = Bid(
      id: _id('bid'),
      lotId: lotId,
      paddleNumber: paddle,
      amount: amount,
      createdAt: now,
      isAuto: auto,
    );
    row.bids.add(bid);
    row.leaderUserId = userId;
    row.lot = row.lot.copyWith(
      currentPrice: amount,
      bidCount: row.lot.bidCount + 1,
      leadingPaddle: paddle,
      endsAt: ends,
    );
    _emit(s.id, BidPlaced(now, _view(row), bid));

    if (previousLeader != null &&
        previousLeader != userId &&
        !previousLeader.startsWith('bot')) {
      notify(
        previousLeader,
        NotificationType.outbid,
        'Bạn vừa bị trả giá cao hơn',
        '${row.lot.book.title}: giá mới ${amount ~/ 1000}k.',
        '/auctions/sessions/${s.id}/live',
      );
    }
    _runProxy(row, s);
    return bid;
  }

  void _runProxy(_LotRow row, AuctionSession s) {
    final p = _proxies[row.lot.id];
    if (p == null || row.leaderUserId == p.userId) return;
    final next = nextBidAmount(
      currentPrice: row.lot.currentPrice,
      bidCount: row.lot.bidCount,
      tiers: config.bidTiers,
    );
    if (next > p.max) return;
    try {
      _bid(row.lot.id, next, userId: p.userId, auto: true);
    } on ServerException {
      _proxies.remove(row.lot.id);
    }
  }

  // ───────────────────────── engine ─────────────────────────

  void _ensureEngine() {
    _engine ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => tick(DateTime.now()),
    );
  }

  /// Một nhịp của bộ máy (gọi mỗi giây; test gọi trực tiếp với thời gian giả).
  void tick(DateTime now) {
    for (final s in List.of(sessions.values)) {
      switch (s.status) {
        case SessionStatus.published when !now.isBefore(s.registrationDeadline):
          final count =
              registrations.values.where((r) => r.sessionId == s.id).length +
              s.registeredCount;
          sessions[s.id] = s.copyWith(
            status: count >= s.minParticipants
                ? SessionStatus.confirmed
                : SessionStatus.postponed,
          );
        case SessionStatus.confirmed when !now.isBefore(s.startAt):
          _openNext(s.id, now);
        case SessionStatus.live:
          _tickLive(s, now);
        default:
          break;
      }
    }
  }

  void _tickLive(AuctionSession s, DateTime now) {
    final cur = s.currentLotId == null ? null : _lots[s.currentLotId];
    final pause = _breaks[s.id];
    if (cur == null || cur.lot.status != LotStatus.live) {
      if (pause == null || !now.isBefore(pause)) _openNext(s.id, now);
      return;
    }
    if (!now.isBefore(cur.lot.endsAt!)) {
      _closeLot(s, cur, now);
      _breaks[s.id] = now.add(const Duration(seconds: 6));
      return;
    }
    // Người chơi ảo.
    final cap = (cur.lot.estimateHigh * 1.1).round();
    if (rnd.nextDouble() < 0.22 && cur.lot.currentPrice < cap) {
      final candidates = _bots
          .where((b) => b != cur.lot.leadingPaddle)
          .toList();
      final paddle = candidates[rnd.nextInt(candidates.length)];
      final next = nextBidAmount(
        currentPrice: cur.lot.currentPrice,
        bidCount: cur.lot.bidCount,
        tiers: config.bidTiers,
      );
      if (next <= cap) {
        try {
          _bid(cur.lot.id, next, userId: 'bot$paddle', botPaddle: paddle);
        } on ServerException {
          // lô vừa đóng
        }
      }
    }
  }

  void _openNext(String sessionId, DateTime now) {
    final s = sessions[sessionId]!;
    final next = _sessionRows(sessionId)
        .where((r) => r.lot.status == LotStatus.scheduled)
        .firstOrNull;
    if (next == null) {
      _endSession(s, now);
      return;
    }
    next.lot = next.lot.copyWith(
      status: LotStatus.live,
      endsAt: now.add(Duration(seconds: s.lotDurationSec)),
      currentPrice: next.lot.startPrice,
      bidCount: 0,
    );
    sessions[sessionId] = s.copyWith(
      status: SessionStatus.live,
      currentLotId: next.lot.id,
    );
    _breaks.remove(sessionId);
    _emit(sessionId, LotOpened(now, _view(next)));
    _changed('auctions');
  }

  void _closeLot(AuctionSession s, _LotRow r, DateTime now) {
    final sold = r.lot.bidCount > 0 && r.lot.currentPrice >= r.reserve;
    r.lot = r.lot.copyWith(
      status: sold ? LotStatus.sold : LotStatus.unsold,
      outcome: sold
          ? LotOutcome.sold
          : (r.lot.bidCount > 0 ? LotOutcome.belowReserve : LotOutcome.noBids),
      hammerPrice: sold ? r.lot.currentPrice : null,
    );
    if (!sold) r.leaderUserId = null;
    final c = consignments[r.consignmentId];
    if (c != null) {
      consignments[c.id] = c.copyWith(
        lotStatus: r.lot.status,
        hammerPrice: r.lot.hammerPrice,
      );
    }
    _emit(s.id, LotClosed(now, _view(r)));
    if (r.leaderUserId != null && !r.leaderUserId!.startsWith('bot')) {
      notify(
        r.leaderUserId!,
        NotificationType.auctionWon,
        'Bạn đã thắng lô ${r.lot.lotNumber}',
        '${r.lot.book.title} — giá gõ búa ${r.lot.currentPrice ~/ 1000}k.',
        '/auctions/sessions/${s.id}/results',
      );
    }
    if (!r.sellerId.startsWith('bot')) {
      notify(
        r.sellerId,
        NotificationType.auctionResult,
        sold ? 'Lô đã bán' : 'Lô chưa bán được',
        r.lot.book.title,
        '/account/seller/consignments',
      );
    }
  }

  void _endSession(AuctionSession s, DateTime now) {
    sessions[s.id] = s.copyWith(
      status: SessionStatus.ended,
      currentLotId: null,
    );
    final rows = _sessionRows(s.id);
    for (final reg
        in registrations.values.where((r) => r.sessionId == s.id).toList()) {
      final uid = _registrationOwner[reg.id]!;
      final won = rows
          .where((r) => r.lot.status == LotStatus.sold && r.leaderUserId == uid)
          .toList();
      if (won.isEmpty) {
        // Không thắng lô nào → mở khoá cọc ngay (SRS 6.6).
        _ledger(
          uid,
          WalletTxnType.depositRelease,
          availableDelta: reg.depositAmount,
          heldDelta: -reg.depositAmount,
          note: 'Hoàn cọc phiên "${s.title}"',
          refType: 'SESSION',
          refId: s.id,
        );
        registrations[reg.id] = reg.copyWith(
          status: RegistrationStatus.refunded,
        );
      } else {
        _createInvoice(s, uid, won, issuedAt: now);
      }
    }
    _emit(s.id, SessionEnded(now));
    _changed('auctions');
    // Giữ demo luôn có một phiên đang chạy.
    if (s.id.startsWith('as1') || s.id.startsWith('demo')) {
      Timer(const Duration(seconds: 20), () => _restartDemo(now));
    }
  }

  void _restartDemo(DateTime from) {
    final id = 'demo${++_seq}';
    const pool = <_LotSeed>[
      (
        book: 'tat-den',
        ed: 1,
        start: 300000,
        low: 500000,
        high: 800000,
        reserve: 450000,
        sig: SignatureStatus.none,
        story: 'Bìa trừu tượng, bản đẹp.',
      ),
      (
        book: 'bi-vo',
        ed: 1,
        start: 350000,
        low: 600000,
        high: 900000,
        reserve: 500000,
        sig: SignatureStatus.none,
        story: 'Bìa hiện đại, bản đẹp.',
      ),
      (
        book: 'vang-bong',
        ed: 1,
        start: 900000,
        low: 1500000,
        high: 2500000,
        reserve: 1300000,
        sig: SignatureStatus.none,
        story: 'Bìa minh hoạ, bản in lại.',
      ),
      (
        book: 'de-men',
        ed: 0,
        start: 400000,
        low: 650000,
        high: 1000000,
        reserve: 600000,
        sig: SignatureStatus.none,
        story: 'Bìa xanh minh hoạ, bản đẹp.',
      ),
    ];
    final s = _makeSession(
      id: id,
      title: 'Phiên chớp nhoáng',
      description: 'Phiên tự tạo để demo luôn có phòng đấu giá đang chạy.',
      startAt: DateTime.now(),
      deposit: 300000,
      minPeople: 3,
      status: SessionStatus.confirmed,
      lots: pool,
      registered: 7,
    );
    for (final uid in _accounts.values.map((a) => a.user.id)) {
      if (walletOf(uid).available >= s.depositAmount &&
          registrations.values.any((r) => _registrationOwner[r.id] == uid)) {
        _register(uid, id, s.depositAmount);
      }
    }
    _changed('auctions');
  }

  /// Hoá đơn lô thắng: giá gõ búa + phí người mua − cọc, hạn 48h (SRS 6.6, 8.2).
  void _createInvoice(
    AuctionSession s,
    String uid,
    List<_LotRow> won, {
    required DateTime issuedAt,
  }) {
    final subtotal = won.fold(0, (n, r) => n + r.lot.currentPrice);
    final premium = fees.buyerPremium(subtotal);
    final reg = _regOf(uid, s.id)!;
    final code = 'AU${++_seq}';
    final o = Order(
      id: 'o$code',
      code: code,
      type: OrderType.auction,
      status: OrderStatus.pendingPayment,
      items: [
        for (final r in won)
          OrderItem(
            id: _id('oi'),
            title: 'Lô ${r.lot.lotNumber} · ${r.lot.book.title}',
            unitPrice: r.lot.currentPrice,
            quantity: 1,
            lotId: r.lot.id,
          ),
      ],
      subtotal: subtotal,
      shippingFee: 0,
      buyerPremium: premium,
      depositApplied: reg.depositAmount,
      total: subtotal + premium - reg.depositAmount,
      createdAt: issuedAt,
      history: [
        OrderStatusChange(
          to: OrderStatus.pendingPayment,
          at: issuedAt,
          note: 'Hoá đơn phiên "${s.title}"',
        ),
      ],
      canReview: false,
      buyerName: _accountById(uid).user.fullName,
      paymentDeadline: issuedAt.add(
        Duration(hours: config.auctionPaymentTimeoutHours),
      ),
    );
    orders[o.id] = o;
    _orderBuyer[o.id] = uid;
    notify(
      uid,
      NotificationType.auctionWon,
      'Hoá đơn lô thắng ${o.code}',
      'Thanh toán trong 48 giờ để nhận sách.',
      '/account/orders',
    );
  }

  /// Cọc được trừ vào hoá đơn khi thanh toán (SRS 8.3).
  void _applyDeposit(String orderId) {
    final o = orders[orderId]!;
    final uid = _orderBuyer[orderId]!;
    final lotId = o.items.first.lotId;
    final sessionId = lotId == null ? null : _lots[lotId]?.lot.sessionId;
    final reg = sessionId == null ? null : _regOf(uid, sessionId);
    if (reg == null || reg.status != RegistrationStatus.approved) return;
    _ledger(
      uid,
      WalletTxnType.payment,
      heldDelta: -reg.depositAmount,
      note: 'Trừ cọc vào hoá đơn ${o.code}',
      refType: 'ORDER',
      refId: o.id,
    );
    registrations[reg.id] = reg.copyWith(status: RegistrationStatus.applied);
  }

  /// Hoàn tất đơn đấu giá → trả người bán: giá gõ búa − hoa hồng (SRS 6.6).
  void _payConsignors(Order o) {
    for (final it in o.items) {
      final r = it.lotId == null ? null : _lots[it.lotId];
      if (r == null) continue;
      final payout = it.unitPrice - fees.sellerCommission(it.unitPrice);
      _ledger(
        r.sellerId,
        WalletTxnType.saleRelease,
        availableDelta: payout,
        note: 'Tiền lô ${r.lot.lotNumber} (đã trừ 15% hoa hồng)',
        refType: 'LOT',
        refId: r.lot.id,
      );
      r.lot = r.lot.copyWith(status: LotStatus.completed);
      final c = consignments[r.consignmentId];
      if (c != null) {
        consignments[c.id] = c.copyWith(
          lotStatus: LotStatus.completed,
          payout: payout,
        );
      }
    }
  }

  // ───────────────────────── admin ─────────────────────────

  List<AuctionSession> adminSessions() =>
      sessions.values.toList()..sort((a, b) => b.startAt.compareTo(a.startAt));

  AuctionSession saveSession(String? id, AuctionSession draft) {
    final existing = id == null ? null : sessions[id];
    if (existing != null &&
        existing.status != SessionStatus.draft &&
        existing.status != SessionStatus.postponed) {
      fail(ErrorCodes.invalidTransition);
    }
    final s = draft.copyWith(
      id: id ?? _id('as'),
      status: existing?.status ?? SessionStatus.draft,
      lotCount: existing?.lotCount ?? 0,
      registeredCount: existing?.registeredCount ?? 0,
    );
    sessions[s.id] = s;
    return s;
  }

  ({AuctionSession session, List<Lot> lots}) setSessionLots(
    String sessionId,
    List<String> lotIds,
  ) {
    final s = sessions[sessionId] ?? fail(ErrorCodes.notFound, 404);
    if (s.status != SessionStatus.draft &&
        s.status != SessionStatus.postponed) {
      fail(ErrorCodes.invalidTransition);
    }
    for (final r in _sessionRows(sessionId)) {
      if (!lotIds.contains(r.lot.id)) {
        r.lot = r.lot.copyWith(
          sessionId: '',
          lotNumber: 0,
          status: LotStatus.ready,
        );
      }
    }
    for (var k = 0; k < lotIds.length; k++) {
      final r = _lots[lotIds[k]] ?? fail(ErrorCodes.notFound, 404);
      r.lot = r.lot.copyWith(
        sessionId: sessionId,
        lotNumber: k + 1,
        status: LotStatus.scheduled,
      );
      final c = consignments[r.consignmentId];
      if (c != null) {
        consignments[c.id] = c.copyWith(lotStatus: LotStatus.scheduled);
      }
    }
    sessions[sessionId] = s.copyWith(lotCount: lotIds.length);
    return catalogue(sessionId);
  }

  AuctionSession publishSession(String id) {
    final s = sessions[id] ?? fail(ErrorCodes.notFound, 404);
    if (s.lotCount == 0 ||
        !(sessionTransitions[s.status]?.contains(SessionStatus.published) ??
            false)) {
      fail(ErrorCodes.invalidTransition);
    }
    sessions[id] = s.copyWith(status: SessionStatus.published);
    _changed('auctions');
    return sessions[id]!;
  }

  AuctionSession pauseSession(String id) {
    final s = sessions[id] ?? fail(ErrorCodes.notFound, 404);
    if (s.status != SessionStatus.live) fail(ErrorCodes.invalidTransition);
    final cur = s.currentLotId == null ? null : _lots[s.currentLotId];
    if (cur?.lot.endsAt != null) {
      _pausedRemaining[id] = cur!.lot.endsAt!.difference(DateTime.now());
    }
    sessions[id] = s.copyWith(status: SessionStatus.paused);
    _emit(id, SessionPaused(DateTime.now()));
    return sessions[id]!;
  }

  AuctionSession resumeSession(String id) {
    final s = sessions[id] ?? fail(ErrorCodes.notFound, 404);
    if (s.status != SessionStatus.paused) fail(ErrorCodes.invalidTransition);
    final cur = s.currentLotId == null ? null : _lots[s.currentLotId];
    if (cur != null && cur.lot.status == LotStatus.live) {
      final remaining =
          _pausedRemaining.remove(id) ?? Duration(seconds: s.softCloseSec);
      cur.lot = cur.lot.copyWith(endsAt: DateTime.now().add(remaining));
    }
    sessions[id] = s.copyWith(status: SessionStatus.live);
    _emit(id, SessionResumed(DateTime.now(), cur == null ? null : _view(cur)));
    return sessions[id]!;
  }

  List<Lot> adminLots({LotStatus? status}) => _lots.values
      .where((r) => status == null || r.lot.status == status)
      .map(_view)
      .toList();

  /// Staff hủy một lô khi có sự cố: lô quay lại chờ xếp phiên.
  Lot cancelLot(String id, String reason) {
    final r = _lots[id] ?? fail(ErrorCodes.notFound, 404);
    final sessionId = r.lot.sessionId;
    final wasCurrent =
        sessions[sessionId]?.currentLotId == id &&
        r.lot.status == LotStatus.live;
    r.lot = r.lot.copyWith(
      status: LotStatus.ready,
      outcome: LotOutcome.cancelled,
      sessionId: '',
      lotNumber: 0,
      endsAt: null,
    );
    r.leaderUserId = null;
    if (wasCurrent) {
      _emit(sessionId, LotClosed(DateTime.now(), _view(r)));
      _breaks[sessionId] = DateTime.now().add(const Duration(seconds: 3));
    }
    _changed('auctions');
    return _view(r);
  }
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
