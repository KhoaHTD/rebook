/// Dữ liệu địa lý đơn giản của Việt Nam để vẽ sơ đồ trong app (không cần mạng, không cần package).
///
/// Toạ độ là (vĩ độ, kinh độ) làm tròn, chỉ đủ cho sơ đồ cơ bản chứ không phải bản đồ trắc địa. Sơ đồ có
/// đủ Quần đảo Hoàng Sa và Quần đảo Trường Sa của Việt Nam (chủ quyền thể hiện ở đây là do app tự vẽ).
library;

typedef GeoPoint = (double lat, double lon);

/// Khung nhìn sơ đồ (độ), gồm cả Hoàng Sa, Trường Sa và vùng biển bao quanh.
abstract final class VietnamGeo {
  static const minLat = 6.4;
  static const maxLat = 23.9;
  static const minLon = 101.8;
  static const maxLon = 117.6;

  /// 63 tỉnh / thành (tên hiển thị) cho ô chọn ở form địa chỉ; mỗi tên đều tra được toạ độ bằng [province].
  static const provinceNames = <String>[
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Hải Phòng',
    'Đà Nẵng',
    'Cần Thơ',
    'An Giang',
    'Bà Rịa - Vũng Tàu',
    'Bạc Liêu',
    'Bắc Giang',
    'Bắc Kạn',
    'Bắc Ninh',
    'Bến Tre',
    'Bình Dương',
    'Bình Định',
    'Bình Phước',
    'Bình Thuận',
    'Cà Mau',
    'Cao Bằng',
    'Đắk Lắk',
    'Đắk Nông',
    'Điện Biên',
    'Đồng Nai',
    'Đồng Tháp',
    'Gia Lai',
    'Hà Giang',
    'Hà Nam',
    'Hà Tĩnh',
    'Hải Dương',
    'Hậu Giang',
    'Hòa Bình',
    'Hưng Yên',
    'Khánh Hòa',
    'Kiên Giang',
    'Kon Tum',
    'Lai Châu',
    'Lâm Đồng',
    'Lạng Sơn',
    'Lào Cai',
    'Long An',
    'Nam Định',
    'Nghệ An',
    'Ninh Bình',
    'Ninh Thuận',
    'Phú Thọ',
    'Phú Yên',
    'Quảng Bình',
    'Quảng Nam',
    'Quảng Ngãi',
    'Quảng Ninh',
    'Quảng Trị',
    'Sóc Trăng',
    'Sơn La',
    'Tây Ninh',
    'Thái Bình',
    'Thái Nguyên',
    'Thanh Hóa',
    'Thừa Thiên Huế',
    'Tiền Giang',
    'Trà Vinh',
    'Tuyên Quang',
    'Vĩnh Long',
    'Vĩnh Phúc',
    'Yên Bái',
  ];

  /// Đường bờ biển + biên giới đất liền, đi ngược chiều kim đồng hồ từ biên giới phía bắc (Hà Giang).
  static const mainland = <GeoPoint>[
    (23.35, 105.30), // Hà Giang
    (22.95, 105.90),
    (22.80, 106.55), // Cao Bằng
    (22.45, 106.75),
    (21.95, 106.75), // Lạng Sơn
    (21.55, 107.35),
    (21.52, 108.05), // Móng Cái
    (21.05, 107.55),
    (20.85, 107.05), // Hạ Long
    (20.72, 106.80), // Hải Phòng
    (20.40, 106.62), // Thái Bình
    (20.10, 106.15), // Ninh Bình
    (19.78, 105.92), // Thanh Hoá
    (19.25, 105.80),
    (18.70, 105.80), // Vinh
    (18.30, 106.20), // Hà Tĩnh
    (17.75, 106.45),
    (17.35, 106.80), // Quảng Bình
    (16.85, 107.30), // Quảng Trị
    (16.45, 107.90), // Huế
    (16.10, 108.30), // Đà Nẵng
    (15.50, 108.80),
    (15.10, 108.95), // Quảng Ngãi
    (14.50, 109.05),
    (13.80, 109.30), // Quy Nhơn
    (13.10, 109.35), // Tuy Hoà
    (12.50, 109.30),
    (12.20, 109.25), // Nha Trang
    (11.85, 109.20), // Cam Ranh
    (11.50, 109.05), // Phan Rang
    (11.10, 108.60),
    (10.90, 108.10), // Phan Thiết
    (10.60, 107.55),
    (10.35, 107.05), // Vũng Tàu
    (10.35, 106.80), // Cần Giờ
    (10.25, 106.65),
    (9.85, 106.60), // Bến Tre
    (9.55, 106.40), // Trà Vinh
    (9.40, 106.05), // Sóc Trăng
    (9.15, 105.65), // Bạc Liêu
    (8.75, 105.10),
    (8.60, 104.82), // mũi Cà Mau
    (8.95, 104.72),
    (9.55, 104.80),
    (9.95, 105.05), // Rạch Giá
    (10.20, 104.85),
    (10.40, 104.50), // Hà Tiên
    (10.55, 104.90), // biên giới Campuchia
    (10.90, 105.45),
    (11.10, 105.85),
    (11.40, 106.10), // Tây Ninh
    (11.75, 106.35),
    (12.00, 106.95),
    (12.30, 107.45),
    (12.90, 107.45),
    (13.50, 107.50),
    (14.40, 107.60), // Kon Tum (biên giới Lào – Campuchia)
    (15.30, 107.40),
    (15.95, 107.30), // biên giới Lào
    (16.35, 106.90),
    (16.60, 106.55), // Lao Bảo
    (17.00, 105.85),
    (17.65, 105.45),
    (18.20, 105.15),
    (18.85, 104.60),
    (19.55, 104.05),
    (20.15, 104.35),
    (20.65, 103.95),
    (21.15, 104.05),
    (21.55, 103.65), // Sơn La – Điện Biên
    (21.20, 103.10),
    (21.95, 102.45),
    (22.45, 102.20), // Mường Nhé
    (22.85, 102.45),
    (22.60, 103.05),
    (22.50, 103.95), // Lào Cai
    (22.85, 104.35),
    (23.35, 105.30),
  ];

  /// Một số đảo lớn gần bờ: Phú Quốc, Côn Đảo, Cát Bà, Lý Sơn.
  static const coastalIslands = <List<GeoPoint>>[
    [
      (10.37, 103.85),
      (10.15, 103.90),
      (10.05, 104.05),
      (10.30, 104.05),
    ], // Phú Quốc
    [(8.72, 106.55), (8.65, 106.65), (8.70, 106.72)], // Côn Đảo
    [(20.82, 106.98), (20.74, 107.02), (20.76, 107.10)], // Cát Bà
    [(15.37, 109.10), (15.36, 109.13)], // Lý Sơn
  ];

  /// Quần đảo Hoàng Sa: cụm đảo quanh (16,5 N; 112 E).
  static const paracel = <GeoPoint>[
    (16.55, 111.60),
    (16.50, 111.80),
    (16.45, 112.00),
    (16.60, 112.30),
    (16.75, 112.35),
    (16.30, 111.55),
    (16.10, 112.35),
    (16.20, 112.55),
    (15.80, 111.75),
  ];

  /// Quần đảo Trường Sa: nhiều cụm đảo, đá, bãi từ (6,5 N đến 12 N), (111 E đến 117 E).
  static const spratly = <GeoPoint>[
    (11.45, 114.35),
    (11.00, 114.28),
    (10.70, 114.30),
    (10.38, 114.20),
    (10.20, 114.55),
    (9.90, 114.35),
    (9.75, 114.00),
    (9.70, 113.85),
    (9.50, 114.15),
    (9.25, 114.60),
    (8.85, 114.15),
    (8.65, 112.90),
    (8.80, 113.45),
    (8.70, 114.50),
    (8.10, 113.95),
    (8.00, 113.75),
    (7.40, 113.60),
    (7.50, 111.60),
    (8.35, 111.90),
    (8.40, 112.10),
    (10.50, 115.75),
    (10.80, 115.80),
    (11.25, 116.10),
    (9.25, 116.60),
    (8.05, 114.60),
  ];

  /// Nhãn đặt ở giữa mỗi quần đảo.
  static const paracelLabel = (lat: 17.75, lon: 112.05);
  static const spratlyLabel = (lat: 12.55, lon: 114.40);

  /// Toạ độ (vĩ độ, kinh độ) gần đúng của trung tâm 63 tỉnh / thành. Khoá là tên không dấu, viết thường.
  static const _provinces = <String, GeoPoint>{
    'ha noi': (21.03, 105.85),
    'hai phong': (20.86, 106.68),
    'quang ninh': (21.01, 107.29),
    'hai duong': (20.94, 106.33),
    'hung yen': (20.65, 106.05),
    'thai binh': (20.45, 106.34),
    'nam dinh': (20.42, 106.17),
    'ha nam': (20.54, 105.92),
    'ninh binh': (20.25, 105.97),
    'vinh phuc': (21.31, 105.60),
    'bac ninh': (21.19, 106.07),
    'bac giang': (21.28, 106.19),
    'lang son': (21.85, 106.76),
    'cao bang': (22.67, 106.26),
    'bac kan': (22.14, 105.83),
    'thai nguyen': (21.59, 105.84),
    'tuyen quang': (21.82, 105.21),
    'ha giang': (22.82, 104.98),
    'phu tho': (21.40, 105.20),
    'yen bai': (21.72, 104.90),
    'lao cai': (22.48, 103.97),
    'son la': (21.33, 103.91),
    'dien bien': (21.39, 103.02),
    'lai chau': (22.40, 103.46),
    'hoa binh': (20.82, 105.34),
    'thanh hoa': (19.80, 105.78),
    'nghe an': (18.68, 105.68),
    'ha tinh': (18.34, 105.90),
    'quang binh': (17.47, 106.62),
    'quang tri': (16.75, 107.19),
    'thua thien hue': (16.46, 107.59),
    'hue': (16.46, 107.59),
    'da nang': (16.05, 108.20),
    'quang nam': (15.57, 108.47),
    'quang ngai': (15.12, 108.80),
    'binh dinh': (13.78, 109.22),
    'phu yen': (13.09, 109.31),
    'khanh hoa': (12.24, 109.19),
    'ninh thuan': (11.56, 108.99),
    'binh thuan': (10.93, 108.10),
    'kon tum': (14.35, 108.00),
    'gia lai': (13.98, 108.00),
    'dak lak': (12.67, 108.04),
    'dak nong': (12.00, 107.69),
    'lam dong': (11.94, 108.44),
    'binh phuoc': (11.75, 106.72),
    'tay ninh': (11.31, 106.10),
    'binh duong': (11.00, 106.65),
    'dong nai': (10.95, 106.82),
    'ba ria vung tau': (10.35, 107.08),
    'vung tau': (10.35, 107.08),
    'ho chi minh': (10.78, 106.70),
    'sai gon': (10.78, 106.70),
    'long an': (10.54, 106.41),
    'tien giang': (10.36, 106.36),
    'ben tre': (10.24, 106.38),
    'tra vinh': (9.93, 106.34),
    'vinh long': (10.25, 105.97),
    'dong thap': (10.46, 105.63),
    'an giang': (10.37, 105.43),
    'kien giang': (10.01, 105.08),
    'can tho': (10.03, 105.78),
    'hau giang': (9.78, 105.47),
    'soc trang': (9.60, 105.97),
    'bac lieu': (9.29, 105.72),
    'ca mau': (9.18, 105.15),
  };

  /// Bỏ dấu tiếng Việt, về chữ thường, bỏ tiền tố "tp.", "thành phố", "tỉnh".
  static String normalize(String s) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final lower = s.toLowerCase();
    final b = StringBuffer();
    for (final r in lower.runes) {
      final ch = String.fromCharCode(r);
      final i = from.indexOf(ch);
      b.write(i < 0 ? ch : to[i]);
    }
    var out = b.toString().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ');
    out = out.replaceAll(RegExp(r'^\s*(tp|thanh pho|tinh)\b'), ' ');
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Toạ độ trung tâm tỉnh / thành có tên [province]; null nếu không nhận ra.
  static GeoPoint? province(String province) {
    final key = normalize(province);
    if (key.isEmpty) return null;
    final exact = _provinces[key];
    if (exact != null) return exact;
    for (final e in _provinces.entries) {
      if (key.contains(e.key)) return e.value;
    }
    return null;
  }
}
