import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';

part 'realtime_client.g.dart';

/// WebSocket JSON thuần của backend: mỗi kênh một kết nối (`/ws/sessions/{id}`,
/// `/ws/notifications`), mỗi tin là một object JSON. Tự nối lại khi rớt mạng.
class RealtimeClient {
  RealtimeClient({required this.url, required this.accessToken});

  /// Gốc WebSocket, ví dụ `ws://localhost:8080/ws`.
  final String url;
  final Future<String?> Function() accessToken;

  static const _retryDelay = Duration(seconds: 3);

  final _reconnects = StreamController<void>.broadcast();
  var _disposed = false;

  /// Phát mỗi lần nối lại thành công sau khi mất kết nối — nơi nghe nên
  /// tải lại ảnh chụp trạng thái vì có thể đã lỡ sự kiện.
  Stream<void> get onReconnect => _reconnects.stream;

  /// Nghe một kênh, ví dụ `sessions/12`. Huỷ subscription thì đóng kết nối.
  Stream<Map<String, dynamic>> subscribe(String channel) {
    late StreamController<Map<String, dynamic>> controller;
    WebSocketChannel? socket;
    StreamSubscription<dynamic>? sub;
    var active = false;
    var connectedBefore = false;

    Future<void> connect() async {
      if (!active || _disposed) return;
      try {
        final token = await accessToken();
        final uri = Uri.parse(
          '$url/$channel${token == null ? '' : '?token=${Uri.encodeQueryComponent(token)}'}',
        );
        final ch = WebSocketChannel.connect(uri);
        socket = ch;
        await ch.ready;
        if (connectedBefore && !_reconnects.isClosed) _reconnects.add(null);
        connectedBefore = true;
        sub = ch.stream.listen(
          (raw) {
            if (raw is! String) return;
            try {
              final decoded = jsonDecode(raw);
              if (decoded is Map<String, dynamic>) controller.add(decoded);
            } on FormatException {
              // Tin không phải JSON (ping…): bỏ qua.
            }
          },
          onDone: () => unawaited(_retry(connect, () => active)),
          onError: (Object e) {
            debugPrint('WebSocket $channel: $e');
            unawaited(_retry(connect, () => active));
          },
          cancelOnError: true,
        );
      } on Object catch (e) {
        debugPrint('WebSocket $channel: $e');
        await _retry(connect, () => active);
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        active = true;
        unawaited(connect());
      },
      onCancel: () async {
        active = false;
        await sub?.cancel();
        await socket?.sink.close();
      },
    );
    return controller.stream;
  }

  Future<void> _retry(
    Future<void> Function() connect,
    bool Function() stillActive,
  ) async {
    await Future<void>.delayed(_retryDelay);
    if (stillActive() && !_disposed) await connect();
  }

  void dispose() {
    _disposed = true;
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
