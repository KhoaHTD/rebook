import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';

part 'upload_service.g.dart';

/// Upload ảnh sách (đăng bán ≥ 3 ảnh, ký gửi, kiểm định, trả hàng).
/// Cuối cùng sẽ upload thẳng lên Cloudinary bằng chữ ký backend cấp (SRS 10.1); hiện backend chưa có endpoint đó.
abstract interface class ImageUploader {
  /// Trả về URL công khai của ảnh.
  Future<String> upload(XFile file, {required String folder});
}

/// Ảnh "đã upload" khi chạy mock: giữ bytes trong bộ nhớ, URL dạng `mem://<id>`.
/// `BookCover` / `PhotoView` đọc từ đây.
abstract final class MemoryImages {
  static final _store = <String, Uint8List>{};
  static var _seq = 0;

  static String put(Uint8List bytes) {
    final key = 'mem://${++_seq}';
    _store[key] = bytes;
    return key;
  }

  static Uint8List? get(String url) => _store[url];
  static bool isMemory(String? url) => url != null && url.startsWith('mem://');
}

class FakeImageUploader implements ImageUploader {
  @override
  Future<String> upload(XFile file, {required String folder}) async =>
      MemoryImages.put(await file.readAsBytes());
}

/// Tạm thời: backend chưa có endpoint cấp chữ ký upload (Cloudinary). Giữ bytes trong
/// bộ nhớ để xem ngay trên máy, nhưng gửi lên backend một URL ảnh mẫu ổn định
/// (cùng nguồn với dữ liệu mẫu) để tin đăng / ký gửi vẫn tạo được.
class PlaceholderImageUploader implements ImageUploader {
  var _seq = 0;

  @override
  Future<String> upload(XFile file, {required String folder}) async {
    MemoryImages.put(await file.readAsBytes());
    return 'https://picsum.photos/seed/rebook-upload-${DateTime.now().millisecondsSinceEpoch}-${_seq++}/600/800';
  }
}

@Riverpod(keepAlive: true)
ImageUploader imageUploader(Ref ref) =>
    Env.useMock ? FakeImageUploader() : PlaceholderImageUploader();
