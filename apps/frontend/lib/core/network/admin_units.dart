import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/shared/data/vietnam_geo.dart';

part 'admin_units.g.dart';

/// Một đơn vị hành chính (quận / huyện / phường / xã): tên hiển thị + mã để tra cấp dưới.
typedef AdminUnit = ({String name, int code});

/// Danh sách quận / huyện của một tỉnh và phường / xã của một quận, để người dùng chọn thay vì gõ.
abstract interface class AdminUnits {
  Future<List<AdminUnit>> districts(String province);

  Future<List<AdminUnit>> wards(int districtCode);
}

/// Khoá so sánh tên: bỏ dấu, bỏ tiền tố cấp ("Thành phố", "Quận", "P.", "Xã"...) để "Phường 12" khớp "P. 12".
String unitKey(String name) {
  final k = VietnamGeo.normalize(name);
  return k
      .replaceFirst(
        RegExp(
          r'^(thanh pho|thi xa|thi tran|quan|huyen|phuong|xa|tp|tx|tt|q|h|p|x)\s+',
        ),
        '',
      )
      .trim();
}

/// Nguồn: provinces.open-api.vn (miễn phí, không cần khoá). Lỗi mạng thì ném lỗi để màn cho nhập tay.
class OpenApiAdminUnits implements AdminUnits {
  OpenApiAdminUnits([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://provinces.open-api.vn/api',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;
  final _districts = <String, List<AdminUnit>>{};
  final _wards = <int, List<AdminUnit>>{};
  Map<String, int>? _provinceCodes;

  Future<int?> _provinceCode(String province) async {
    final codes = _provinceCodes ??= {
      for (final p in (await _dio.get<List<dynamic>>('/p/')).data!)
        unitKey((p as Map<String, dynamic>)['name'] as String):
            p['code'] as int,
    };
    return codes[unitKey(province)];
  }

  List<AdminUnit> _units(Object? list) => [
    for (final u in (list as List<dynamic>? ?? const []))
      (
        name: (u as Map<String, dynamic>)['name'] as String,
        code: u['code'] as int,
      ),
  ];

  @override
  Future<List<AdminUnit>> districts(String province) async {
    final key = unitKey(province);
    final cached = _districts[key];
    if (cached != null) return cached;
    final code = await _provinceCode(province);
    if (code == null) return const [];
    final res = await _dio.get<Map<String, dynamic>>(
      '/p/$code',
      queryParameters: {'depth': 2},
    );
    return _districts[key] = _units(res.data!['districts']);
  }

  @override
  Future<List<AdminUnit>> wards(int districtCode) async {
    final cached = _wards[districtCode];
    if (cached != null) return cached;
    final res = await _dio.get<Map<String, dynamic>>(
      '/d/$districtCode',
      queryParameters: {'depth': 2},
    );
    return _wards[districtCode] = _units(res.data!['wards']);
  }
}

@Riverpod(keepAlive: true)
AdminUnits adminUnits(Ref ref) => OpenApiAdminUnits();
