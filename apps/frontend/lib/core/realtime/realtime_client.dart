import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';

part 'realtime_client.g.dart';

/// Kết nối WebSocket STOMP tới backend (SRS 10.3).
///
/// - Nghe: `subscribe('/topic/sessions/{id}')`, lỗi riêng: `subscribe('/user/queue/errors')`.
/// - Gửi: `send('/app/lots/{lotId}/bid', {'amount': ...})`.
///
/// Một kết nối dùng chung cho cả app; tự kết nối lại (reconnectDelay). Khi kết nối lại,
/// repository phải gọi `GET /sessions/{id}/state` rồi mới nghe tiếp (xem auction feature).
class RealtimeClient {
  RealtimeClient({required this.url, required this.accessToken});

  final String url;
  final Future<String?> Function() accessToken;

  StompClient? _client;
  Completer<void>? _connected;
  final _reconnects = StreamController<void>.broadcast();

  /// Phát mỗi lần kết nối (lại) thành công — dùng để tải lại ảnh chụp trạng thái.
  Stream<void> get onReconnect => _reconnects.stream;

  Future<StompClient> _ensureConnected() async {
    if (_client != null && _connected != null) {
      await _connected!.future;
      return _client!;
    }
    final token = await accessToken();
    _connected = Completer<void>();
    final client = StompClient(
      config: StompConfig(
        url: url,
        reconnectDelay: const Duration(seconds: 3),
        stompConnectHeaders: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        onConnect: (_) {
          if (!(_connected?.isCompleted ?? true)) _connected!.complete();
          _reconnects.add(null);
        },
        onWebSocketError: (dynamic e) => debugPrint('STOMP error: $e'),
        onStompError: (frame) => debugPrint('STOMP frame error: ${frame.body}'),
      ),
    );
    _client = client..activate();
    await _connected!.future;
    return client;
  }

  /// Nghe một destination; mỗi message là JSON đã decode.
  Stream<Map<String, dynamic>> subscribe(String destination) {
    late StreamController<Map<String, dynamic>> controller;
    void Function({Map<String, String>? unsubscribeHeaders})? unsubscribe;
    controller = StreamController<Map<String, dynamic>>(
      onListen: () async {
        final client = await _ensureConnected();
        unsubscribe = client.subscribe(
          destination: destination,
          callback: (frame) {
            final body = frame.body;
            if (body == null) return;
            final decoded = jsonDecode(body);
            if (decoded is Map<String, dynamic>) controller.add(decoded);
          },
        );
      },
      onCancel: () => unsubscribe?.call(),
    );
    return controller.stream;
  }

  Future<void> send(String destination, Map<String, Object?> body) async {
    final client = await _ensureConnected();
    client.send(destination: destination, body: jsonEncode(body));
  }

  void dispose() {
    _client?.deactivate();
    _reconnects.close();
  }
}

@Riverpod(keepAlive: true)
RealtimeClient realtimeClient(Ref ref) {
  final storage = ref.watch(tokenStorageProvider);
  final client = RealtimeClient(
    url: Env.wsBaseUrl,
    accessToken: () async => (await storage.read())?.accessToken,
  );
  ref.onDispose(client.dispose);
  return client;
}
