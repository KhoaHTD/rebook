import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';

part 'auction_floor_providers.g.dart';

/// Các lô của những phiên đang LIVE hoặc sắp diễn ra (gom từ catalogue từng phiên).
@riverpod
Future<List<Lot>> activeLots(Ref ref) async {
  final sessions = await ref.watch(auctionSessionsProvider.future);
  final active = sessions
      .where(
        (s) =>
            SessionTab.live.matches(s.status) ||
            SessionTab.upcoming.matches(s.status),
      )
      .take(6);
  final lots = <Lot>[];
  for (final s in active) {
    final (_, l) = await ref.watch(sessionCatalogueProvider(s.id).future);
    lots.addAll(l);
  }
  return lots;
}

/// Lô nổi bật: ước tính cao nhất trong các phiên sắp tới.
@riverpod
Future<List<Lot>> featuredLots(Ref ref) async {
  final lots = [...await ref.watch(activeLotsProvider.future)];
  lots.sort((a, b) => b.estimateHigh.compareTo(a.estimateHigh));
  return lots.take(10).toList();
}

/// Lô người dùng đang theo dõi.
@riverpod
Future<List<Lot>> watchedLots(Ref ref) async {
  final lots = await ref.watch(activeLotsProvider.future);
  return lots.where((l) => l.watched).toList();
}
