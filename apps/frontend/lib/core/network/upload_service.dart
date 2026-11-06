import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/api/generated/export.dart';
import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/core/network/api_providers.dart';

part 'upload_service.g.dart';

/// Upload ảnh sách (đăng bán ≥ 3 ảnh, ký gửi, kiểm định, trả hàng, biên lai rút tiền).
abstract interface class ImageUploader {
  /// Trả về URL của ảnh. Ảnh lên backend là URL tương đối (`/files/...`); hiển thị qua [resolveImageUrl].
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

/// Backend lưu ảnh với URL tương đối (`/files/<tên>`) để đổi máy chủ (tunnel, máy ảo `10.0.2.2`) không làm hỏng
/// dữ liệu; lúc hiển thị mới ghép với địa chỉ API đang dùng. URL đầy đủ, `assets/`, `mem://` giữ nguyên.
String resolveImageUrl(String url) {
  if (!url.startsWith('/')) return url;
  final base = Env.apiBaseUrl.endsWith('/')
      ? Env.apiBaseUrl.substring(0, Env.apiBaseUrl.length - 1)
      : Env.apiBaseUrl;
  return '$base$url';
}

/// Ảnh riêng tư (biên lai chuyển khoản có số tài khoản, BE-34): backend đòi token, nên không tải bằng URL trần.
bool isPrivateFile(String url) => url.startsWith('/files/private/');

/// Tải ảnh riêng tư kèm token qua Dio của app (có `AuthInterceptor`). Không có trong spec nên không qua client sinh.
@riverpod
Future<Uint8List> privateImage(Ref ref, String url) async {
  final res = await guardApi(
    () => ref
        .watch(dioProvider)
        .get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        ),
  );
  return Uint8List.fromList(res.data ?? const []);
}

class FakeImageUploader implements ImageUploader {
  @override
  Future<String> upload(XFile file, {required String folder}) async =>
      MemoryImages.put(await file.readAsBytes());
}

/// Upload thật lên backend (`POST /files`, PNG / JPEG / WebP, tối đa 5MB).
/// `folder` chỉ để phân loại phía app; backend lưu chung một chỗ.
class ApiImageUploader implements ImageUploader {
  ApiImageUploader(this._client);

  final RestClient _client;

  @override
  Future<String> upload(XFile file, {required String folder}) =>
      guardApi(() async {
        final bytes = await file.readAsBytes();
        final res = await _client.files.postFiles(
          file: MultipartFile.fromBytes(
            bytes,
            filename: file.name.isEmpty ? 'image.jpg' : file.name,
            contentType: DioMediaType.parse(
              file.mimeType ?? _guessType(file.name),
            ),
          ),
        );
        return res.url ?? '';
      });

  /// Backend kiểm tra loại ảnh theo Content-Type của phần file; `mimeType` thường trống trên điện thoại.
  static String _guessType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}

@Riverpod(keepAlive: true)
ImageUploader imageUploader(Ref ref) => Env.useMock
    ? FakeImageUploader()
    : ApiImageUploader(ref.watch(restClientProvider));
