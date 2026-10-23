import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/core/network/api_providers.dart';

part 'upload_service.g.dart';

/// Upload ảnh sách (đăng bán ≥ 3 ảnh, ký gửi, kiểm định, trả hàng).
/// App upload thẳng lên Cloudinary bằng chữ ký backend cấp; backend chỉ lưu URL (SRS 10.1).
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

class CloudinaryImageUploader implements ImageUploader {
  CloudinaryImageUploader(this._client, this._dio);

  final api.RestClient _client;
  final Dio _dio;

  @override
  Future<String> upload(XFile file, {required String folder}) =>
      guardApi(() async {
        final sig = await _client.uploads.createUploadSignature(
          body: api.UploadSignatureRequest(folder: folder),
        );
        final form = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: file.name,
          ),
          'api_key': sig.apiKey,
          'timestamp': sig.timestamp,
          'signature': sig.signature,
          'folder': sig.folder,
        });
        final res = await _dio.post<Map<String, dynamic>>(
          'https://api.cloudinary.com/v1_1/${sig.cloudName}/image/upload',
          data: form,
        );
        return res.data!['secure_url'] as String;
      });
}

@Riverpod(keepAlive: true)
ImageUploader imageUploader(Ref ref) => Env.useMock
    ? FakeImageUploader()
    : CloudinaryImageUploader(ref.watch(restClientProvider), Dio());
