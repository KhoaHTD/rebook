import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

/// Áp một sự kiện realtime lên ảnh chụp phòng đấu giá.
///
/// Thuần Dart để test được; phòng đấu giá chỉ giữ trạng thái, server quyết định mọi thứ.
SessionState applyAuctionEvent(SessionState s, AuctionEvent e) {
  List<Lot> replaceLot(Lot lot) => [
    for (final l in s.lots) l.id == lot.id ? lot : l,
  ];

  return switch (e) {
    LotOpened(:final lot) => s.copyWith(
      session: s.session.copyWith(
        currentLotId: lot.id,
        status: SessionStatus.live,
      ),
      currentLot: lot,
      lots: replaceLot(lot),
      recentBids: const [],
      serverTime: e.serverTime,
    ),
    BidPlaced(:final lot, :final bid) => s.copyWith(
      currentLot: s.currentLot?.id == lot.id ? lot : s.currentLot,
      lots: replaceLot(lot),
      recentBids: [
        bid,
        ...s.recentBids.where((b) => b.id != bid.id),
      ].take(30).toList(),
      serverTime: e.serverTime,
    ),
    LotClosed(:final lot) => s.copyWith(
      currentLot: s.currentLot?.id == lot.id ? lot : s.currentLot,
      lots: replaceLot(lot),
      serverTime: e.serverTime,
    ),
    SessionPaused() => s.copyWith(
      session: s.session.copyWith(status: SessionStatus.paused),
      serverTime: e.serverTime,
    ),
    SessionResumed(:final lot) => s.copyWith(
      session: s.session.copyWith(status: SessionStatus.live),
      currentLot: lot ?? s.currentLot,
      lots: lot == null ? s.lots : replaceLot(lot),
      serverTime: e.serverTime,
    ),
    SessionEnded() => s.copyWith(
      session: s.session.copyWith(status: SessionStatus.ended),
      serverTime: e.serverTime,
    ),
  };
}

/// Có được bấm "Trả giá" không, và vì sao không (để hiển thị đúng lời nhắc).
enum BidBlock { none, notRegistered, notLive, leading, overLimit }

BidBlock bidBlockFor(SessionState s, {required int nextAmount}) {
  final reg = s.myRegistration;
  final lot = s.currentLot;
  if (reg == null || reg.status != RegistrationStatus.approved) {
    return BidBlock.notRegistered;
  }
  if (s.session.status != SessionStatus.live ||
      lot == null ||
      lot.status != LotStatus.live) {
    return BidBlock.notLive;
  }
  if (lot.leadingPaddle == reg.paddleNumber && lot.bidCount > 0) {
    return BidBlock.leading;
  }
  // Hạn mức tính trên tổng giá các lô đang dẫn / đã thắng (SRS 5.4).
  if (nextAmount > reg.remainingLimit) return BidBlock.overLimit;
  return BidBlock.none;
}
