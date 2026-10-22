import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/home/domain/home_feed.dart';
import 'package:book_marketplace/features/home/domain/home_repository.dart';
import 'package:book_marketplace/shared/data/book_mapper.dart';

/// Trang chủ ghép từ: tin mới (`GET /listings`), thể loại gốc (`GET /categories`),
/// lịch phiên (`GET /sessions` + catalogue từng phiên) và lô đang chạy (`/sessions/{id}/state`).
class ApiHomeRepository implements HomeRepository {
  ApiHomeRepository(this._client);

  final api.RestClient _client;

  static const _upcoming = {
    api.SessionStatus.published,
    api.SessionStatus.postponed,
    api.SessionStatus.confirmed,
  };

  @override
  Future<HomeFeed> getFeed() => guardApi(() async {
    final (listings, categories, sessions) = await (
      _client.catalog.getListings(size: 12),
      _client.catalog.getCategories(),
      _client.auction.getSessions(size: 20),
    ).wait;

    final active = (sessions.items ?? const <api.SessionSummary>[])
        .where(
          (s) =>
              _upcoming.contains(s.status) ||
              s.status == api.SessionStatus.live ||
              s.status == api.SessionStatus.paused,
        )
        .toList();
    final details = await Future.wait([
      for (final s in active) _client.auction.getSessionsId(id: s.id!),
    ]);

    LotTeaser? liveLot;
    final upcoming = <SessionTeaser>[];
    final featured = <LotTeaser>[];
    for (final d in details) {
      final s = d.session!;
      final lots = d.lots ?? const <api.LotPublic>[];
      if (s.status == api.SessionStatus.live && liveLot == null) {
        final state = await _client.auction.getSessionsIdState(id: s.id!);
        final cur = state.currentLot;
        if (cur != null && cur.status == api.LotStatus.open) {
          liveLot = LotTeaser(
            id: sid(cur.id),
            title: cur.title ?? '',
            author: '',
            imageUrl: cur.coverUrl,
            lotNumber: cur.lotNumber,
            lotCount: s.lotCount,
            sessionTitle: s.title,
            currentPrice: vnd(cur.currentPrice ?? cur.startPrice),
            endsAt: cur.endsAt?.toLocal() ?? DateTime.now(),
          );
        }
      }
      if (_upcoming.contains(s.status) && lots.isNotEmpty) {
        upcoming.add(
          SessionTeaser(
            firstLotId: sid(lots.first.id),
            title: s.title ?? '',
            startsAt: s.startAt?.toLocal() ?? DateTime.now(),
            lotCount: s.lotCount ?? lots.length,
            deposit: s.depositAmount?.toInt(),
          ),
        );
        for (final l in lots) {
          featured.add(
            LotTeaser(
              id: sid(l.id),
              title: l.title ?? '',
              author: l.author ?? '',
              imageUrl: l.coverUrl,
              lotNumber: l.lotNumber,
              lotCount: s.lotCount,
              sessionTitle: s.title,
              estimateLow: l.estimateLow?.toInt(),
              estimateHigh: l.estimateHigh?.toInt(),
              currentPrice: vnd(l.currentPrice ?? l.startPrice),
              endsAt: s.startAt?.toLocal() ?? DateTime.now(),
            ),
          );
        }
      }
    }

    return HomeFeed(
      newListings: (listings.items ?? const []).map((l) => l.toBook()).toList(),
      categories: [
        for (final c in categories.take(4))
          HomeCategory(id: sid(c.id), name: c.name ?? ''),
      ],
      liveLot: liveLot,
      upcomingSessions: upcoming,
      featuredLots: featured,
    );
  });
}
