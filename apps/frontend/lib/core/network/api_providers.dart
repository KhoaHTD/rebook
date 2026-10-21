import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/api/generated/export.dart';
import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';
import 'package:book_marketplace/core/network/auth_interceptor.dart';

part 'api_providers.g.dart';

BaseOptions _baseOptions() => BaseOptions(
  baseUrl: Env.apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 15),
  contentType: Headers.jsonContentType,
);

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(
      storage: ref.watch(tokenStorageProvider),
      refreshDio: Dio(_baseOptions()),
      onSessionExpired: () =>
          ref.read(sessionControllerProvider.notifier).signOut(),
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('$o'),
      ),
    );
  }
  return dio;
}

/// Client sinh từ OpenAPI. Repository trong `features/*/data/` dùng cái này,
/// KHÔNG tự gọi `dio.get('/...')`.
@Riverpod(keepAlive: true)
RestClient restClient(Ref ref) => RestClient(ref.watch(dioProvider));
