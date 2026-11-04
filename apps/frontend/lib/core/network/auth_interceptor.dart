import 'package:dio/dio.dart';

import 'package:book_marketplace/api/generated/export.dart';
import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/auth/token_storage.dart';

/// Gắn `Authorization: Bearer` cho mọi request và tự refresh token khi gặp 401.
/// QueuedInterceptor đảm bảo nhiều request lỗi cùng lúc chỉ refresh một lần.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this._storage,
    required Dio refreshDio,
    required this._onSessionExpired,
  }) : _authClient = AuthClient(refreshDio),
       _retryDio = refreshDio;

  final TokenStorage _storage;
  final AuthClient _authClient;
  final Dio _retryDio;
  final Future<void> Function() _onSessionExpired;

  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await _storage.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final current = await _storage.read();
    if (current == null) return handler.next(err);

    try {
      final pair = await _authClient.postAuthRefresh(
        body: RefreshRequest(refreshToken: current.refreshToken),
      );
      final access = pair.accessToken;
      final refresh = pair.refreshToken;
      if (access == null || refresh == null) throw StateError('no tokens');
      await _storage.write(
        AuthTokens(accessToken: access, refreshToken: refresh),
      );
      options
        ..extra[_retriedKey] = true
        ..headers['Authorization'] = 'Bearer $access';
      handler.resolve(await _retryDio.fetch<dynamic>(options));
    } catch (_) {
      await _onSessionExpired();
      handler.next(err);
    }
  }
}
