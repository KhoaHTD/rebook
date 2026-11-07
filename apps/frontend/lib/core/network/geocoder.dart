import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/shared/data/vietnam_geo.dart';

part 'geocoder.g.dart';

/// Địa chỉ cần định vị, tách theo cấp để dò từ khu vực lớn xuống số nhà.
typedef AddressQuery = ({
  String street,
  String ward,
  String district,
  String province,
});

/// Đổi địa chỉ gõ tay thành toạ độ để tự ghim lên bản đồ.
abstract interface class Geocoder {
  /// Trả toạ độ gần nhất tìm được (số nhà → phường → quận → tỉnh); không có thì `null`.
  /// Lỗi mạng cũng trả `null`: ghim tự động chỉ là tiện ích, người dùng vẫn chạm bản đồ để đặt tay.
  Future<GeoPoint?> locate(AddressQuery address);
}

/// Chạy khi không có mạng: lấy tâm tỉnh.
class FakeGeocoder implements Geocoder {
  @override
  Future<GeoPoint?> locate(AddressQuery address) async =>
      VietnamGeo.province(address.province);
}

/// Nominatim của OpenStreetMap (miễn phí, không cần khoá). Quy định sử dụng: tối đa 1 yêu cầu / giây,
/// không dùng cho gợi ý khi đang gõ, có User-Agent định danh ứng dụng.
class NominatimGeocoder implements Geocoder {
  NominatimGeocoder([Dio? dio, this.pause = const Duration(milliseconds: 1100)])
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

  /// Nghỉ giữa hai yêu cầu liên tiếp (giới hạn 1 yêu cầu / giây của Nominatim).
  final Duration pause;
  var _first = true;

  /// Viết tắt thường gặp → dạng đầy đủ để Nominatim khớp tên.
  static String clean(String s) => s
      .trim()
      .replaceFirst(RegExp(r'^TP\.?\s+', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^P\.\s*', caseSensitive: false), 'Phường ')
      .replaceFirst(RegExp(r'^Q\.\s*', caseSensitive: false), 'Quận ')
      .replaceFirst(RegExp(r'^H\.\s*', caseSensitive: false), 'Huyện ')
      .replaceFirst(RegExp(r'^X\.\s*', caseSensitive: false), 'Xã ')
      .replaceFirst(RegExp(r'^TX\.?\s+', caseSensitive: false), 'Thị xã ')
      .replaceFirst(RegExp(r'^TT\.?\s+', caseSensitive: false), 'Thị trấn ');

  /// Một lần gọi Nominatim; trả kết quả đầu tiên hoặc null.
  Future<({GeoPoint point, String kind})?> _search(String q) async {
    if (!_first) await Future<void>.delayed(pause);
    _first = false;
    final res = await _dio.get<List<dynamic>>(
      '/search',
      queryParameters: {
        'q': q,
        'format': 'jsonv2',
        'limit': 1,
        'countrycodes': 'vn',
      },
    );
    final hit = res.data;
    if (hit == null || hit.isEmpty) return null;
    final m = hit.first as Map<String, dynamic>;
    final lat = double.tryParse('${m['lat']}');
    final lon = double.tryParse('${m['lon']}');
    if (lat == null || lon == null) return null;
    return (point: (lat, lon), kind: '${m['category']}');
  }

  /// Kết quả nằm trong vùng quanh tâm tỉnh (loại kết quả rác ở tỉnh khác).
  static bool _nearProvince(GeoPoint p, GeoPoint? centre) =>
      centre == null ||
      ((p.$1 - centre.$1).abs() < 1.2 && (p.$2 - centre.$2).abs() < 1.2);

  /// Dò từ chi tiết đến thô: địa chỉ đầy đủ → số nhà + phường → số nhà + quận → tên đường + quận
  /// → phường → quận. Hai cấp cuối chỉ nhận ranh giới hành chính để khỏi ghim nhầm vào một cửa hàng trùng tên.
  @override
  Future<GeoPoint?> locate(AddressQuery address) async {
    _first = true;
    final ward = clean(address.ward);
    final district = clean(address.district);
    final province = clean(address.province);
    final centre = VietnamGeo.province(address.province);
    final street = address.street.split(',').first.trim();
    final bare = street.replaceFirst(RegExp(r'^\d+[A-Za-z]?([/-]\d+)*\s+'), '');
    String join(List<String> parts) =>
        [...parts.where((e) => e.isNotEmpty), 'Việt Nam'].join(', ');

    final detailed = <String>{
      if (street.isNotEmpty) ...[
        join([address.street.trim(), ward, district, province]),
        join([street, ward, district, province]),
        join([street, district, province]),
        join([bare, district, province]),
      ],
    };
    final areas = <String>{
      join([ward, district, province]),
      join([district, province]),
    };
    try {
      for (final q in detailed) {
        final hit = await _search(q);
        if (hit != null && _nearProvince(hit.point, centre)) return hit.point;
      }
      for (final q in areas) {
        final hit = await _search(q);
        if (hit != null &&
            (hit.kind == 'boundary' || hit.kind == 'place') &&
            _nearProvince(hit.point, centre)) {
          return hit.point;
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Nominatim: ${e.response?.statusCode ?? e.type}');
      return null;
    }
  }
}

/// Photon (komoot, dữ liệu OpenStreetMap): dự phòng khi Nominatim không tới được (một số mạng chặn tên miền
/// openstreetmap.org nên không phân giải được DNS). Cùng cách dò từ chi tiết đến thô, kết quả phải nằm gần tỉnh.
class PhotonGeocoder implements Geocoder {
  PhotonGeocoder([Dio? dio, this.pause = const Duration(milliseconds: 400)])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://photon.komoot.io',
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              // Photon cũng từ chối User-Agent mặc định của Dart (403).
              headers: {
                'User-Agent':
                    'rebook-book-marketplace/1.0 (PRM393 FPT University)',
              },
            ),
          );

  final Dio _dio;
  final Duration pause;
  var _first = true;

  /// Một lần gọi Photon: toạ độ và tên đường / tên địa điểm của kết quả đầu tiên (để kiểm tra có đúng đường không).
  Future<({GeoPoint point, String label})?> _search(String q) async {
    if (!_first) await Future<void>.delayed(pause);
    _first = false;
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/',
      queryParameters: {
        'q': q,
        'limit': 1,
        // lon_min, lat_min, lon_max, lat_max: chỉ trong lãnh thổ Việt Nam.
        'bbox': '102.0,8.2,114.5,23.5',
      },
    );
    final features = res.data?['features'];
    if (features is! List || features.isEmpty) return null;
    final first = features.first as Map<String, dynamic>;
    final coords =
        (first['geometry'] as Map<String, dynamic>?)?['coordinates']
            as List<dynamic>?;
    if (coords == null || coords.length < 2) return null;
    final props = (first['properties'] as Map<String, dynamic>?) ?? const {};
    return (
      point: ((coords[1] as num).toDouble(), (coords[0] as num).toDouble()),
      label: '${props['street'] ?? ''} ${props['name'] ?? ''}',
    );
  }

  @override
  Future<GeoPoint?> locate(AddressQuery address) async {
    _first = true;
    final ward = NominatimGeocoder.clean(address.ward);
    final district = NominatimGeocoder.clean(address.district);
    final province = NominatimGeocoder.clean(address.province);
    final centre = VietnamGeo.province(address.province);
    final street = address.street.split(',').first.trim();
    // Tên đường (bỏ số nhà): kết quả theo địa chỉ chỉ nhận khi đúng đường này, tránh ghim nhầm sang đường khác.
    final bare = VietnamGeo.normalize(
      street.replaceFirst(RegExp(r'^\d+[A-Za-z]?([/-]\d+)*\s+'), ''),
    );
    String join(List<String> parts) =>
        [...parts.where((e) => e.isNotEmpty), 'Việt Nam'].join(', ');
    final byStreet = <String>{
      if (street.isNotEmpty) join([street, ward, district, province]),
      if (street.isNotEmpty) join([street, district, province]),
    };
    final byArea = <String>{
      join([ward, district, province]),
      join([district, province]),
    };
    try {
      for (final q in byStreet) {
        final hit = await _search(q);
        debugPrint('Photon $q -> ${hit?.point} ${hit?.label}');
        if (hit != null &&
            NominatimGeocoder._nearProvince(hit.point, centre) &&
            (bare.isEmpty || VietnamGeo.normalize(hit.label).contains(bare))) {
          return hit.point;
        }
      }
      for (final q in byArea) {
        final hit = await _search(q);
        if (hit != null && NominatimGeocoder._nearProvince(hit.point, centre)) {
          return hit.point;
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Photon: ${e.response?.statusCode ?? e.type}');
      return null;
    }
  }
}

/// Thử [primary] trước; không ra kết quả (mất mạng, địa chỉ lạ) thì lấy [fallback].
class FallbackGeocoder implements Geocoder {
  FallbackGeocoder(this.primary, this.fallback);

  final Geocoder primary;
  final Geocoder fallback;

  @override
  Future<GeoPoint?> locate(AddressQuery address) async =>
      await primary.locate(address) ?? await fallback.locate(address);
}

/// Mock cũng định vị thật (cần mạng): Nominatim, không tới được thì Photon, cuối cùng ghim ở tâm tỉnh.
@Riverpod(keepAlive: true)
Geocoder geocoder(Ref ref) => FallbackGeocoder(
  NominatimGeocoder(),
  FallbackGeocoder(PhotonGeocoder(), FakeGeocoder()),
);
