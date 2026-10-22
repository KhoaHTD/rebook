import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/features/auction/domain/auction.dart';
import 'package:book_marketplace/shared/data/book_mapper.dart';
import 'package:book_marketplace/shared/domain/book.dart';

/// Thông tin của phiên + người dùng cần để dựng trạng thái lô trong phòng đấu giá.
class RoomContext {
  RoomContext({required this.session, this.me, this.proxyMax});

  final api.SessionDetail session;
  api.RegistrationResponse? me;
  num? proxyMax;

  /// Catalogue từng lô (tác giả, tình trạng, ước tính) — LotLive không có các trường này.
  final lots = <int, api.LotDetail>{};

  int get lotDurationSeconds => session.lotDurationSec ?? 60;
  String? get myPaddle => me?.paddle;
}

extension LotLiveMapper on api.LotLive {
  /// [previous] là trạng thái trước của cùng lô — dùng để nhận biết đồng hồ vừa được gia hạn.
  Auction toAuction(RoomContext ctx, {Auction? previous}) {
    final detail = id == null ? null : ctx.lots[id];
    final summary = ctx.session.session;
    final price = vnd(currentPrice ?? startPrice);
    final open = status == api.LotStatus.open;
    final now = DateTime.now();
    var end = endsAt?.toLocal() ?? now;
    if (!open && end.isAfter(now)) end = now; // lô đã đóng / huỷ
    final sameLot = previous != null && previous.id == sid(id);
    // Đồng hồ bị đẩy lùi do có giá mới ở giây cuối (soft close); giữ huy hiệu tới khi lô đổi giờ lần nữa.
    final extended =
        sameLot &&
        (end.isAfter(previous.endsAt.add(const Duration(seconds: 1))) ||
            (previous.softCloseExtended && end == previous.endsAt));
    final me = ctx.myPaddle;

    return Auction(
      id: sid(id),
      book: Book(
        id: sid(id),
        title: title ?? '',
        author: detail?.book?.author ?? '',
        condition:
            detail?.book?.conditionGrade.toDomain() ?? BookCondition.unknown,
        price: price,
        sellerName: '',
        imageUrl: coverUrl,
      ),
      currentPrice: price,
      minIncrement: vnd(increment) == 0
          ? bidIncrementFor(price)
          : vnd(increment),
      serverNextMinBid: nextMinBid == null ? null : vnd(nextMinBid),
      endsAt: end,
      bidCount: bidCount ?? 0,
      highestBidder: leadingPaddle,
      youAreLeading: me != null && leadingPaddle == me,
      recentBids: [
        for (final b in recentBids ?? const <api.BidView>[])
          BidEntry(
            paddle: b.paddle ?? '',
            amount: vnd(b.amount),
            at: b.at?.toLocal() ?? now,
            isYou: me != null && b.paddle == me,
            auto: b.auto ?? false,
          ),
      ],
      reserveMet: switch (closeResult) {
        api.LotCloseResult.sold => true,
        api.LotCloseResult.reserveNotMet => false,
        _ => null,
      },
      lotNumber: lotNumber,
      lotCount: summary?.lotCount,
      sessionTitle: summary?.title,
      edition: detail?.book.edition(),
      estimateLow: detail?.lot?.estimateLow?.toInt(),
      estimateHigh: detail?.lot?.estimateHigh?.toInt(),
      bidLimit: ctx.me?.bidLimit?.toInt(),
      proxyMax: ctx.proxyMax?.toInt(),
      softCloseExtended: extended,
      lotDurationSeconds: ctx.lotDurationSeconds,
    );
  }
}

extension LotPublicMapper on api.LotPublic {
  /// Lô trong danh sách (chưa vào phòng): giá, giờ mở dự kiến, ước tính.
  Auction toAuction(api.SessionDetail session) {
    final s = session.session;
    final now = DateTime.now();
    final start = vnd(startPrice);
    final price = currentPrice == null ? start : vnd(currentPrice);
    final open = status == api.LotStatus.open;
    final duration = Duration(seconds: session.lotDurationSec ?? 60);
    // Lô chưa tới lượt: giờ mở ≈ giờ bắt đầu phiên (phiên đã chạy thì coi như sắp tới).
    var opensAt = s?.startAt?.toLocal() ?? now;
    if (!open && !opensAt.isAfter(now)) {
      opensAt = now.add(const Duration(minutes: 1));
    }
    return Auction(
      id: sid(id),
      book: Book(
        id: sid(id),
        title: title ?? '',
        author: author ?? '',
        condition: conditionGrade.toDomain(),
        price: price,
        sellerName: '',
        imageUrl: coverUrl,
      ),
      currentPrice: price,
      minIncrement: bidIncrementFor(price),
      serverNextMinBid: currentPrice == null ? start : null,
      endsAt: open ? (endsAt?.toLocal() ?? now) : opensAt.add(duration),
      opensAt: open ? null : opensAt,
      bidCount: bidCount ?? 0,
      lotNumber: lotNumber,
      lotCount: s?.lotCount,
      sessionTitle: s?.title,
      estimateLow: estimateLow?.toInt(),
      estimateHigh: estimateHigh?.toInt(),
      bidLimit: session.myRegistration?.bidLimit?.toInt(),
      lotDurationSeconds: session.lotDurationSec ?? 60,
    );
  }
}

extension LotDetailMapper on api.LotDetail {
  LotDetail toDomain(api.SessionDetail session) {
    final l = lot;
    final s = session.session;
    final start = vnd(l?.startPrice);
    final deposit = s?.depositAmount?.toInt();
    final reg = session.myRegistration;
    final registered =
        reg != null &&
        (reg.status == api.RegistrationStatus.approved ||
            reg.status == api.RegistrationStatus.applied);
    return LotDetail(
      id: sid(l?.id),
      book: Book(
        id: sid(book?.id),
        title: book?.title ?? l?.title ?? '',
        author: book?.author ?? l?.author ?? '',
        condition: (book?.conditionGrade ?? l?.conditionGrade).toDomain(),
        price: start,
        sellerName: '',
        imageUrl: book?.coverUrl ?? l?.coverUrl,
        description: book?.description,
      ),
      startPrice: start,
      minIncrement: bidIncrementFor(start),
      opensAt: s?.startAt?.toLocal() ?? DateTime.now(),
      lotNumber: l?.lotNumber,
      lotCount: s?.lotCount,
      sessionTitle: s?.title,
      edition: book.edition(),
      estimateLow: l?.estimateLow?.toInt(),
      estimateHigh: l?.estimateHigh?.toInt(),
      deposit: deposit,
      bidLimit:
          reg?.bidLimit?.toInt() ?? (deposit == null ? null : deposit * 10),
      lotDurationSeconds: session.lotDurationSec,
      softCloseSeconds: session.softCloseSec,
      conditionReport: conditionReport,
      inspection: _checklist(checklist),
      following: l?.watching ?? false,
      isLive: l?.status == api.LotStatus.open,
      registered: registered,
    );
  }
}

extension on api.BookResponse? {
  /// "Tân Dân · 1940"
  String? edition() {
    final b = this;
    if (b == null) return null;
    final parts = [?b.publisher, if (b.publishYear != null) '${b.publishYear}'];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Checklist kiểm định của backend: {fullPages, editionVerified, mold, notes, signature}.
List<InspectionItem> _checklist(Map<String, dynamic>? raw) {
  if (raw == null) return const [];
  bool? flag(String key) => raw[key] is bool ? raw[key] as bool : null;
  final full = flag('fullPages');
  final edition = flag('editionVerified');
  final mold = flag('mold');
  final notes = flag('notes');
  final signature = raw['signature'];
  return [
    if (full != null)
      InspectionItem(check: InspectionCheck.fullPages, ok: full),
    if (edition != null)
      InspectionItem(check: InspectionCheck.edition, ok: edition),
    if (mold != null) InspectionItem(check: InspectionCheck.mold, ok: !mold),
    if (notes != null) InspectionItem(check: InspectionCheck.notes, ok: !notes),
    if (signature is String && signature.isNotEmpty)
      InspectionItem(
        check: InspectionCheck.signature,
        ok: false,
        note: signature,
      ),
  ];
}
