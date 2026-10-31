/// Cấu hình theo môi trường, truyền vào bằng `--dart-define-from-file=env/<tên>.json`.
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  /// Endpoint STOMP của backend Spring (SRS 10.3).
  static const wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8080/ws',
  );

  /// `true`: dùng dữ liệu giả trong `shared/data/fake`, chạy được khi chưa có backend.
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  /// Bật thông báo đẩy FCM — chỉ bật khi đã cấu hình Firebase project.
  static const fcmEnabled = bool.fromEnvironment('FCM_ENABLED');

  /// Trang VNPay quay về sau khi thanh toán (deep link app / URL web).
  static const paymentReturnUrl = String.fromEnvironment(
    'PAYMENT_RETURN_URL',
    defaultValue: 'http://localhost:8080/payment-return',
  );
}
