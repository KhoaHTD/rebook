import 'package:url_launcher/url_launcher.dart';

/// Mở trang ngoài (cổng ZaloPay). Web mở tab mới: tab app chuyển sang màn kết quả và tự hỏi lại trạng thái,
/// nên không phụ thuộc việc ZaloPay có đưa trình duyệt quay về hay không (app sandbox dùng chung không quay về).
Future<bool> openExternal(String url) => launchUrl(
  Uri.parse(url),
  mode: LaunchMode.externalApplication,
  webOnlyWindowName: '_blank',
);

/// Cổng thanh toán giả lập (mock, hoặc backend chưa cấu hình ZaloPay) dùng `mock://...` thay cho URL thật.
bool isMockUrl(String? url) => url != null && url.startsWith('mock://');
