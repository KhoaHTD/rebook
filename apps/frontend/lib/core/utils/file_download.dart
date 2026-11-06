// Tải một file văn bản (vd. CSV) về máy. Chỉ web có trình duyệt để tải; nơi khác `canDownloadFiles` là false (UI ẩn nút).
export 'package:book_marketplace/core/utils/file_download_stub.dart'
    if (dart.library.js_interop) 'package:book_marketplace/core/utils/file_download_web.dart';
