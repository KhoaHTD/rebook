/// Cấu hình theo môi trường, truyền vào bằng `--dart-define-from-file=env/<tên>.json`.
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );

  /// `true`: dùng repository giả trong `data/fake_*`, chạy được khi chưa có backend.
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
}
