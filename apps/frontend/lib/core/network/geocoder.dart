import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/shared/data/vietnam_geo.dart';

part 'geocoder.g.dart';

/// Đổi địa chỉ gõ tay thành toạ độ để tự ghim lên bản đồ.
abstract interface class Geocoder {
  /// Thử lần lượt các chuỗi tìm (chi tiết → thô), trả toạ độ của chuỗi đầu tiên tìm thấy; không có thì `null`.
  /// Lỗi mạng cũng trả `null`: ghim tự động chỉ là tiện ích, người dùng vẫn chạm bản đồ để đặt tay.
  Future<GeoPoint?> locate(List<String> queries);
}

/// Chạy mock: không gọi mạng, lấy tâm tỉnh / thành có trong chuỗi tìm.
class FakeGeocoder implements Geocoder {
  @override
  Future<GeoPoint?> locate(List<String> queries) async {
    for (final q in queries.reversed) {
      for (final name in VietnamGeo.provinceNames) {
        if (VietnamGeo.normalize(q).contains(VietnamGeo.normalize(name))) {
          return VietnamGeo.province(name);
        }
      }
    }
    return null;
  }
}

/// Nominatim của OpenStreetMap (miễn phí, không cần khoá). Quy định sử dụng: tối đa 1 yêu cầu / giây,
/// không dùng cho gợi ý khi đang gõ, có Referer / User-Agent định danh ứng dụng.
class NominatimGeocoder implements Geocoder {
  NominatimGeocoder([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://nominatim.openstreetmap.org',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {
                'Accept-Language': 'vi',
                // Nominatim chặn User-Agent mặc định của Dart; phải định danh ứng dụng.
                'User-Agent':
                    'rebook-book-marketplace/1.0 (PRM393 FPT University)',
              },
            ),
          );

  final Dio _dio;

  @override
  Future<GeoPoint?> locate(List<String> queries) async {
    for (var i = 0; i < queries.length; i++) {
      if (i > 0) await Future<void>.delayed(const Duration(milliseconds: 1100));
      try {
        final res = await _dio.get<List<dynamic>>(
          '/search',
          queryParameters: {
            'q': queries[i],
            'format': 'jsonv2',
            'limit': 1,
            'countrycodes': 'vn',
          },
        );
        final hit = res.data;
        if (hit != null && hit.isNotEmpty) {
          final m = hit.first as Map<String, dynamic>;
          final lat = double.tryParse('${m['lat']}');
          final lon = double.tryParse('${m['lon']}');
          if (lat != null && lon != null) return (lat, lon);
        }
      } on DioException catch (e) {
        debugPrint('Nominatim: ${e.response?.statusCode ?? e.type}');
        return null;
      }
    }
    return null;
  }
}

/// Thử [primary] trước; không ra kết quả (mất mạng, địa chỉ lạ) thì lấy [fallback].
class FallbackGeocoder implements Geocoder {
  FallbackGeocoder(this.primary, this.fallback);

  final Geocoder primary;
  final Geocoder fallback;

  @override
  Future<GeoPoint?> locate(List<String> queries) async =>
      await primary.locate(queries) ?? await fallback.locate(queries);
}

/// Mock cũng định vị thật bằng Nominatim (cần mạng); không có mạng thì ghim ở tâm tỉnh.
@Riverpod(keepAlive: true)
Geocoder geocoder(Ref ref) =>
    FallbackGeocoder(NominatimGeocoder(), FakeGeocoder());
