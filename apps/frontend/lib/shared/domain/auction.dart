import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

part 'auction.freezed.dart';

/// Phiên đấu giá: nhiều lô chạy lần lượt (SRS 6.3 – 6.5).
@freezed
abstract class AuctionSession with _$AuctionSession {
  const AuctionSession._();

  const factory AuctionSession({
    required String id,
    required String title,
    required DateTime startAt,
    required DateTime registrationDeadline,
    required int minParticipants,
    required int depositAmount,
    required int lotDurationSec,
    required int softCloseSec,
    required SessionStatus status,
    required int lotCount,
    required int registeredCount,
    String? description,
    String? coverImageUrl,
    String? currentLotId,
    @Default(0) int watcherCount,
  }) = _AuctionSession;

  bool get isLive =>
      status == SessionStatus.live || status == SessionStatus.paused;
  bool get acceptsRegistration =>
      (status == SessionStatus.published ||
          status == SessionStatus.confirmed) &&
      DateTime.now().isBefore(registrationDeadline);
}

/// Một lô đấu giá. Giá sàn (reserve) không bao giờ có ở đây.
@freezed
abstract class Lot with _$Lot {
  const factory Lot({
    required String id,
    required String sessionId,
    required int lotNumber,
    required Book book,
    required int estimateLow,
    required int estimateHigh,
    required int startPrice,
    required int currentPrice,
    required int bidCount,
    required LotStatus status,
    required bool watched,
    String? story,
    String? conditionReport,
    @Default(SignatureStatus.none) SignatureStatus signature,
    LotOutcome? outcome,
    DateTime? endsAt,
    int? hammerPrice,
    String? leadingPaddle,
  }) = _Lot;
}

@freezed
abstract class Registration with _$Registration {
  const Registration._();

  const factory Registration({
    required String id,
    required String sessionId,
    required String sessionTitle,
    required String paddleNumber,
    required int depositAmount,
    required int bidLimit,
    required int committedAmount,
    required RegistrationStatus status,
  }) = _Registration;

  int get remainingLimit => bidLimit - committedAmount;
}

@freezed
abstract class Bid with _$Bid {
  const factory Bid({
    required String id,
    required String lotId,
    required String paddleNumber,
    required int amount,
    required DateTime createdAt,
    @Default(false) bool isAuto,
  }) = _Bid;
}

/// Ảnh chụp trạng thái phiên, lấy khi vào phòng hoặc kết nối lại (SRS 10.3).
@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState({
    required AuctionSession session,
    required List<Lot> lots,
    required DateTime serverTime,
    required List<Bid> recentBids,
    Lot? currentLot,
    Registration? myRegistration,
    @Default(0) int viewerCount,
  }) = _SessionState;
}

@freezed
abstract class LotResult with _$LotResult {
  const factory LotResult({
    required String lotId,
    required int lotNumber,
    required String title,
    required LotOutcome outcome,
    int? hammerPrice,
    String? winnerPaddle,
    @Default(false) bool wonByMe,
  }) = _LotResult;
}

@freezed
abstract class SessionResult with _$SessionResult {
  const factory SessionResult({
    required AuctionSession session,
    required List<LotResult> results,
  }) = _SessionResult;
}

/// Lời mời mua lần hai gửi người trả giá cao thứ hai khi người thắng bỏ thanh toán (SRS 6.6): mua với giá họ đã trả,
/// hạn 24h; chỉ mời khi giá ≥ giá sàn.
@freezed
abstract class SecondChanceOffer with _$SecondChanceOffer {
  const factory SecondChanceOffer({
    required String id,
    required String lotId,
    required int lotNumber,
    required String bookTitle,
    required int amount,
    required DateTime expiresAt,
    required SecondChanceStatus status,
    String? coverUrl,
  }) = _SecondChanceOffer;
}

/// Sự kiện realtime trên /topic/sessions/{id} (SRS 10.3).
sealed class AuctionEvent {
  const AuctionEvent(this.serverTime);
  final DateTime serverTime;
}

final class LotOpened extends AuctionEvent {
  const LotOpened(super.serverTime, this.lot);
  final Lot lot;
}

final class BidPlaced extends AuctionEvent {
  const BidPlaced(super.serverTime, this.lot, this.bid);
  final Lot lot;
  final Bid bid;
}

final class LotClosed extends AuctionEvent {
  const LotClosed(super.serverTime, this.lot);
  final Lot lot;
}

final class SessionPaused extends AuctionEvent {
  const SessionPaused(super.serverTime);
}

final class SessionResumed extends AuctionEvent {
  const SessionResumed(super.serverTime, this.lot);
  final Lot? lot;
}

final class SessionEnded extends AuctionEvent {
  const SessionEnded(super.serverTime);
}
