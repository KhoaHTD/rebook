import 'package:url_launcher/url_launcher.dart';

/// Mở trang ngoài (cổng VNPay). Web mở trong cùng tab để VNPay quay về đúng app.
Future<bool> openExternal(String url) => launchUrl(
  Uri.parse(url),
  mode: LaunchMode.externalApplication,
  webOnlyWindowName: '_self',
);

/// Cổng thanh toán giả lập (mock, hoặc backend chưa cấu hình VNPay) dùng `mock://...` thay cho URL thật.
bool isMockUrl(String? url) => url != null && url.startsWith('mock://');
