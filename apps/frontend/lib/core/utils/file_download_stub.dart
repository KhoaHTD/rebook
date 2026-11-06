/// Không có trình duyệt để tải file: báo không hỗ trợ.
bool get canDownloadFiles => false;

Future<bool> downloadTextFile(
  String filename,
  String content, {
  String mime = 'text/csv',
}) async => false;
