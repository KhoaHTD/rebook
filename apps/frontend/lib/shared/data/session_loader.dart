import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/auction.dart';

/// Ảnh chụp phòng đấu giá: ghép `GET /sessions/{id}` (danh mục lô, đăng ký của tôi)
/// với `GET /sessions/{id}/state` (lô đang đấu, đồng hồ server, bước giá).
/// Backend không có endpoint gộp nên cả catalog / auction / admin dùng chung hàm này.
Future<SessionState> loadSessionState(
  api.RestClient client,
  String sessionId,
) async {
  final id = apiId(sessionId);
  final detail = await client.auction.getSessionsId(id: id);
  final live = await client.auction.getSessionsIdState(id: id);

  var session = detail.sessionToDomain();
  final lots = detail.lotsToDomain();
  final liveLot = live.currentLot;

  Lot? current;
  if (liveLot != null) {
    final base = lots.where((l) => l.id == '${liveLot.id}').firstOrNull;
    current = lotLiveToDomain(liveLot, base: base, sessionId: sessionId);
    final idx = lots.indexWhere((l) => l.id == current!.id);
    if (idx >= 0) {
      lots[idx] = current;
    } else {
      lots.add(current);
    }
  }
  if (live.status != null) {
    session = session.copyWith(
      status: sessionStatusToDomain(live.status),
      currentLotId: current?.id,
    );
  }
  final reg = live.me ?? detail.myRegistration;
  return SessionState(
    session: session,
    lots: lots,
    serverTime: live.serverTime ?? DateTime.now(),
    recentBids: liveLot == null ? const [] : bidsToDomain(liveLot),
    currentLot: current,
    myRegistration: reg?.toDomain(sessionTitle: session.title),
  );
}
