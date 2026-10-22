import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';

part 'push_service.g.dart';

/// Một thông báo đẩy nhận được khi app đang mở.
class PushMessage {
  const PushMessage({required this.title, required this.body, this.link});
  final String title;
  final String body;

  /// Đường dẫn trong app (vd /account/orders/123).
  final String? link;
}

/// Thông báo đẩy (SRS mục 3: đơn hàng, sắp tới phiên, bị trả giá cao hơn, thắng đấu giá).
///
/// Đây là nơi DUY NHẤT dùng Firebase SDK. Feature chỉ biết interface này.
abstract interface class PushService {
  /// Xin quyền và lấy FCM token (null nếu không bật / không hỗ trợ).
  Future<String?> init();

  Stream<PushMessage> get messages;

  /// Người dùng chạm vào thông báo khi app ở nền.
  Stream<PushMessage> get opened;
}

/// Dùng khi chưa có Firebase project (FCM_ENABLED=false): không làm gì.
class NoopPushService implements PushService {
  @override
  Future<String?> init() async => null;
  @override
  Stream<PushMessage> get messages => const Stream.empty();
  @override
  Stream<PushMessage> get opened => const Stream.empty();
}

/// FCM thật. Cần cấu hình Firebase (google-services.json / GoogleService-Info.plist,
/// firebase-messaging-sw.js cho web) trước khi bật FCM_ENABLED.
class FcmPushService implements PushService {
  PushMessage _map(RemoteMessage m) => PushMessage(
    title: m.notification?.title ?? '',
    body: m.notification?.body ?? '',
    link: m.data['link'] as String?,
  );

  @override
  Future<String?> init() async {
    try {
      await Firebase.initializeApp();
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      // getToken vẫn chạy ở firebase_messaging 17; chuyển sang register()/onRegistered khi nâng cấp.
      // ignore: deprecated_member_use
      return await fm.getToken();
    } on Object catch (e) {
      debugPrint('FCM init failed: $e');
      return null;
    }
  }

  @override
  Stream<PushMessage> get messages => FirebaseMessaging.onMessage.map(_map);

  @override
  Stream<PushMessage> get opened =>
      FirebaseMessaging.onMessageOpenedApp.map(_map);
}

@Riverpod(keepAlive: true)
PushService pushService(Ref ref) =>
    Env.fcmEnabled ? FcmPushService() : NoopPushService();
