import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';

part 'realtime_client.g.dart';

/// Kết nối WebSocket tới backend, tự kết nối lại với backoff.
/// Mỗi [subscribe] mở một kênh `<WS_BASE_URL>/<channel>?token=<jwt>`
/// và phát ra từng message JSON đã decode.
///
/// Nếu backend dùng giao thức khác (STOMP, SignalR, Socket.IO) thì chỉ sửa file này —
/// các repository bên trên vẫn nhận `Stream<Map<String, dynamic>>` như cũ.
class RealtimeClient {
  RealtimeClient({required this._baseUri, required this._accessToken});

  final Uri _baseUri;
  final Future<String?> Function() _accessToken;

  Stream<Map<String, dynamic>> subscribe(String channel) {
    late StreamController<Map<String, dynamic>> controller;
    WebSocketChannel? socket;
    StreamSubscription<dynamic>? sub;
    var attempt = 0;
    var closed = false;

    Future<void> connect() async {
      void reconnect() {
        if (closed) return;
        final seconds = min(30, pow(2, attempt++).toInt());
        Timer(Duration(seconds: seconds), connect);
      }

      if (closed) return;
      final token = await _accessToken();
      final uri = _baseUri.replace(
        path: '${_baseUri.path}/$channel',
        queryParameters: {'token': ?token},
      );
      try {
        socket = WebSocketChannel.connect(uri);
        await socket!.ready;
        attempt = 0;
        sub = socket!.stream.listen(
          (raw) {
            final decoded = jsonDecode(raw as String);
            if (decoded is Map<String, dynamic>) controller.add(decoded);
          },
          onDone: () => reconnect(),
          onError: (Object e) {
            debugPrint('Realtime[$channel] error: $e');
            reconnect();
          },
          cancelOnError: true,
        );
      } catch (e) {
        debugPrint('Realtime[$channel] connect failed: $e');
        reconnect();
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: connect,
      onCancel: () async {
        closed = true;
        await sub?.cancel();
        await socket?.sink.close();
      },
    );
    return controller.stream;
  }
}

@Riverpod(keepAlive: true)
RealtimeClient realtimeClient(Ref ref) {
  final storage = ref.watch(tokenStorageProvider);
  return RealtimeClient(
    baseUri: Uri.parse(Env.wsBaseUrl),
    accessToken: () async => (await storage.read())?.accessToken,
  );
}
