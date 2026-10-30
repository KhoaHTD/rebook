import 'package:flutter/material.dart';

/// Design tokens — style Liquid Glass đã duyệt (`design-preview/png/lg-*.png`).
/// Widget KHÔNG hardcode số đo / màu — luôn lấy từ đây hoặc từ Theme.
abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Khoảng cách giữa các poster trong lưới (ngang / dọc).
  static const posterGapX = 30.0;
  static const posterGapY = 34.0;

  /// Lề trang desktop (vùng nội dung bên phải sidebar).
  static const pageX = 44.0;
  static const pageTop = 46.0;
}

abstract final class AppRadius {
  static const sm = Radius.circular(10);
  static const md = Radius.circular(20);
  static const lg = Radius.circular(26);
  static const pill = Radius.circular(999);

  static const card = BorderRadius.all(md);
  static const sidebar = BorderRadius.all(lg);
  static const item = BorderRadius.all(sm);
  static const chip = BorderRadius.all(pill);

  /// Bìa sách: gáy (trái) bo ít, mép (phải) bo hơn — như cuốn sách thật.
  static const poster = BorderRadius.only(
    topLeft: Radius.circular(3),
    bottomLeft: Radius.circular(3),
    topRight: Radius.circular(6),
    bottomRight: Radius.circular(6),
  );
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
}

/// Font chữ: font hệ thống (`null` = mặc định của nền tảng: SF trên iOS / macOS, Roboto trên Android,
/// Segoe UI trên Windows). Không đóng gói font riêng. Giữ ba tên để chỗ nào cần đổi font chỉ sửa ở đây.
abstract final class AppFonts {
  static const String? sans = null;

  /// Tiêu đề trang, tiêu đề kệ, dòng sự kiện: cũng dùng font hệ thống.
  static const String? serif = null;

  /// Chữ nội dung.
  static const String? family = sans;
}

/// Màu riêng của style Liquid Glass, ngoài ColorScheme.
/// Dùng: `context.appColors.tint`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.sidebar,
    required this.selected,
    required this.onSelected,
    required this.shelfAlt,
    required this.fill,
    required this.separator,
    required this.secondaryText,
    required this.tertiaryText,
    required this.badgeNew,
    required this.live,
    required this.success,
    required this.warning,
    required this.info,
    required this.tabBar,
    required this.posterShadow,
    required this.tint,
    required this.tintSoft,
    required this.glassTop,
    required this.glassBottom,
    required this.glassBorder,
    required this.glassShadow,
    required this.background,
    required this.ambient,
  });

  /// Nền khối thông tin trong trang (kính trong, không làm mờ).
  final Color sidebar;

  /// Lựa chọn "mạnh" (chip đang chọn, chấm hiện tại): nền xanh, chữ trắng.
  final Color selected;
  final Color onSelected;

  /// Nền xen kẽ giữa các kệ trên mobile.
  final Color shelfAlt;

  /// Nền ô nhập, nút phụ.
  final Color fill;
  final Color separator;
  final Color secondaryText;
  final Color tertiaryText;

  /// Chip "MỚI" đặt lên bìa (kính tối).
  final Color badgeNew;

  /// Đấu giá đang diễn ra, chip "ĐẤU GIÁ", đồng hồ.
  final Color live;
  final Color success;
  final Color warning;
  final Color info;

  /// Lớp kính sáng của mục đang chọn trên tab bar.
  final Color tabBar;
  final Color posterShadow;

  /// Màu nhấn xanh: nút chính, mục đang chọn, liên kết.
  final Color tint;

  /// Nền kính ánh xanh của mục đang chọn trong sidebar.
  final Color tintSoft;

  /// Kính lỏng: dải màu trên → dưới, viền sáng, bóng.
  final Color glassTop;
  final Color glassBottom;
  final Color glassBorder;
  final Color glassShadow;

  /// Nền dưới lớp màu loang.
  final Color background;

  /// Các vệt màu loang phía sau kính (xem [AmbientPalette]).
  final List<(Color, Alignment, double)> ambient;

  static const light = AppColors(
    sidebar: Color(0x8CFFFFFF),
    selected: Color(0xFF0A6CFF),
    onSelected: Color(0xFFFFFFFF),
    shelfAlt: Color(0x59FFFFFF),
    fill: Color(0x12000000),
    separator: Color(0x1A000000),
    secondaryText: Color(0xFF6E6E73),
    tertiaryText: Color(0xFF8E8E93),
    badgeNew: Color(0x611E1E20),
    live: Color(0xFFE5352B),
    success: Color(0xFF1F8A46),
    warning: Color(0xFFB25000),
    info: Color(0xFF0A6CFF),
    tabBar: Color(0xB8FFFFFF),
    posterShadow: Color(0x73000000),
    tint: Color(0xFF0A6CFF),
    tintSoft: Color(0x290A6CFF),
    glassTop: Color(0xA8FFFFFF),
    glassBottom: Color(0x57FFFFFF),
    glassBorder: Color(0xB3FFFFFF),
    glassShadow: Color(0x2219233C),
    background: Color(0xFFEBEFF4),
    ambient: AmbientPalette.light,
  );

  static const dark = AppColors(
    sidebar: Color(0x332C2C2E),
    selected: Color(0xFF0A84FF),
    onSelected: Color(0xFFFFFFFF),
    shelfAlt: Color(0x1FFFFFFF),
    fill: Color(0x1FFFFFFF),
    separator: Color(0x26FFFFFF),
    secondaryText: Color(0xFF98989D),
    tertiaryText: Color(0xFF636366),
    badgeNew: Color(0x611E1E20),
    live: Color(0xFFFF6961),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    info: Color(0xFF64A8FF),
    tabBar: Color(0x2EFFFFFF),
    posterShadow: Color(0x99000000),
    tint: Color(0xFF0A84FF),
    tintSoft: Color(0x3D0A84FF),
    glassTop: Color(0x6B3A3A3C),
    glassBottom: Color(0x4D1C1C1E),
    glassBorder: Color(0x26FFFFFF),
    glassShadow: Color(0x66000000),
    background: Color(0xFF111114),
    ambient: AmbientPalette.dark,
  );

  /// Khu đấu giá: nền tối ấm như phòng đấu giá, đỏ LIVE + vàng đồng. Luôn tối, không theo máy.
  static const auction = AppColors(
    sidebar: Color(0x4D2A2A2A),
    selected: Color(0xFFFFFFFF),
    onSelected: Color(0xFF000000),
    shelfAlt: Color(0x14FFFFFF),
    fill: Color(0x1FFFFFFF),
    separator: Color(0x26FFFFFF),
    secondaryText: Color(0xFFB3B3B3),
    tertiaryText: Color(0xFF7A7A7A),
    badgeNew: Color(0x66000000),
    live: Color(0xFFFF4A3D),
    success: Color(0xFF4CD27C),
    warning: Color(0xFFE9A23B),
    info: Color(0xFF8DB8FF),
    tabBar: Color(0x33FFFFFF),
    posterShadow: Color(0xB3000000),
    tint: Color(0xFFF2F2F2),
    tintSoft: Color(0x26FFFFFF),
    glassTop: Color(0x6B3A3A3A),
    glassBottom: Color(0x4D161616),
    glassBorder: Color(0x33FFFFFF),
    glassShadow: Color(0x99000000),
    background: Color(0xFF000000),
    ambient: AmbientPalette.auction,
  );

  @override
  AppColors copyWith({
    Color? sidebar,
    Color? selected,
    Color? onSelected,
    Color? shelfAlt,
    Color? fill,
    Color? separator,
    Color? secondaryText,
    Color? tertiaryText,
    Color? badgeNew,
    Color? live,
    Color? success,
    Color? warning,
    Color? info,
    Color? tabBar,
    Color? posterShadow,
    Color? tint,
    Color? tintSoft,
    Color? glassTop,
    Color? glassBottom,
    Color? glassBorder,
    Color? glassShadow,
    Color? background,
    List<(Color, Alignment, double)>? ambient,
  }) => AppColors(
    sidebar: sidebar ?? this.sidebar,
    selected: selected ?? this.selected,
    onSelected: onSelected ?? this.onSelected,
    shelfAlt: shelfAlt ?? this.shelfAlt,
    fill: fill ?? this.fill,
    separator: separator ?? this.separator,
    secondaryText: secondaryText ?? this.secondaryText,
    tertiaryText: tertiaryText ?? this.tertiaryText,
    badgeNew: badgeNew ?? this.badgeNew,
    live: live ?? this.live,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    tabBar: tabBar ?? this.tabBar,
    posterShadow: posterShadow ?? this.posterShadow,
    tint: tint ?? this.tint,
    tintSoft: tintSoft ?? this.tintSoft,
    glassTop: glassTop ?? this.glassTop,
    glassBottom: glassBottom ?? this.glassBottom,
    glassBorder: glassBorder ?? this.glassBorder,
    glassShadow: glassShadow ?? this.glassShadow,
    background: background ?? this.background,
    ambient: ambient ?? this.ambient,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      sidebar: l(sidebar, other.sidebar),
      selected: l(selected, other.selected),
      onSelected: l(onSelected, other.onSelected),
      shelfAlt: l(shelfAlt, other.shelfAlt),
      fill: l(fill, other.fill),
      separator: l(separator, other.separator),
      secondaryText: l(secondaryText, other.secondaryText),
      tertiaryText: l(tertiaryText, other.tertiaryText),
      badgeNew: l(badgeNew, other.badgeNew),
      live: l(live, other.live),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      tabBar: l(tabBar, other.tabBar),
      posterShadow: l(posterShadow, other.posterShadow),
      tint: l(tint, other.tint),
      tintSoft: l(tintSoft, other.tintSoft),
      glassTop: l(glassTop, other.glassTop),
      glassBottom: l(glassBottom, other.glassBottom),
      glassBorder: l(glassBorder, other.glassBorder),
      glassShadow: l(glassShadow, other.glassShadow),
      background: l(background, other.background),
      ambient: t < 0.5 ? ambient : other.ambient,
    );
  }
}

/// Các vệt màu loang phía sau kính (lấy tông từ bìa sách): màu, tâm (theo tỉ lệ màn hình), bán kính (theo cạnh ngắn).
abstract final class AmbientPalette {
  /// Nền sáng trắng phẳng, không vệt màu (chỉ nền tối còn vệt loang).
  static const light = <(Color, Alignment, double)>[];

  static const dark = <(Color, Alignment, double)>[
    (Color(0x667A4A22), Alignment(-0.55, -0.75), 0.75),
    (Color(0x66243C70), Alignment(0.55, -0.9), 0.8),
    (Color(0x4D6E2620), Alignment(0.8, 0.55), 0.65),
    (Color(0x4D2D4A36), Alignment(-0.35, 0.85), 0.7),
  ];

  /// Khu đấu giá: nền đen phẳng, không vệt màu loang.
  static const auction = <(Color, Alignment, double)>[];
}

/// Màu ván kệ kính ở trang Khám phá (pastel đậm vừa): cam, xanh dương, tím, xanh lá, hồng, vàng.
abstract final class ShelfPalette {
  static const colors = <Color>[
    Color(0xFFF2A33A),
    Color(0xFF3FA0F5),
    Color(0xFF9B7BEA),
    Color(0xFF4DBB8A),
    Color(0xFFEA6F9A),
    Color(0xFFE8C53D),
  ];

  static Color at(int i) => colors[i % colors.length];

  /// Bóng đổ dưới tấm ván.
  static const shadow = Color(0x26000000);
}

/// Thẻ mời sang khu đấu giá đặt ở app mua sách (nền đen → xám đậm, chữ trắng): đối lập với khu mua sách sáng.
abstract final class AuctionPalette {
  static const entry = <Color>[Color(0xFF000000), Color(0xFF2A2A2A)];
  static const ink = Color(0xFFFFFFFF);
}

/// Bảng màu giao diện quản trị (Staff / Admin): dashboard sáng, phẳng, nút đen.
abstract final class AdminPalette {
  static const bg = Color(0xFFF5F6F8);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE5E7EB);
  static const lineSoft = Color(0xFFF0F1F4);
  static const ink = Color(0xFF111318);
  static const muted = Color(0xFF6B7280);
  static const faint = Color(0xFF9AA0AB);
  static const ok = Color(0xFF17924F);
  static const okSoft = Color(0xFFE4F5EA);
  static const warn = Color(0xFFC27A00);
  static const warnSoft = Color(0xFFFDF1D9);
  static const bad = Color(0xFFD6453D);
  static const badSoft = Color(0xFFFDE8E6);
  static const info = Color(0xFF0A6CFF);
  static const infoSoft = Color(0xFFE6F0FF);
  static const selected = Color(0xFFF2F6FF);
  static const barIdle = Color(0xFFE4E7EC);
}

/// Nền slide sự kiện của băng chuyền trang chủ (ký gửi, mở shop…) và lớp phủ đọc chữ trên ảnh bìa.
abstract final class HeroPalette {
  static const consign = <Color>[Color(0xFFD9822B), Color(0xFF8C2F4B)];
  static const shop = <Color>[Color(0xFF1F8A8A), Color(0xFF1C3D6E)];
  static const ring = Color(0x26FFFFFF);
  static const glyph = Color(0x2EFFFFFF);

  /// Tối ở phía chữ → trong ở phía ảnh.
  static const scrim = <Color>[Color(0xB3000000), Color(0x14000000)];
}

/// Cặp màu cho bìa tự vẽ (khi sách chưa có ảnh). Màu đến từ bìa, giao diện giữ trung tính.
abstract final class CoverPalette {
  static const pairs = <(Color, Color)>[
    (Color(0xFFB8382B), Color(0xFFF6EEE4)),
    (Color(0xFFD9CFC0), Color(0xFF2B2620)),
    (Color(0xFF1F1D1B), Color(0xFFE9E1D2)),
    (Color(0xFFE8E0CF), Color(0xFF3A2E22)),
    (Color(0xFF3E4A3A), Color(0xFFEFE9DC)),
    (Color(0xFFC9B48F), Color(0xFF2F2A22)),
    (Color(0xFF2F3B33), Color(0xFFE3E6DC)),
    (Color(0xFFEFE8DC), Color(0xFF3B3530)),
    (Color(0xFF7D8D93), Color(0xFFF4F1EA)),
    (Color(0xFFE2C044), Color(0xFF2A2620)),
    (Color(0xFF1C3D6E), Color(0xFFEAE6DA)),
    (Color(0xFF8C2F4B), Color(0xFFF5E9EC)),
  ];

  /// Lớp sáng/tối giả gáy sách ở mép trái bìa.
  static const spine = <Color>[
    Color(0x47000000),
    Color(0x47FFFFFF),
    Color(0x14000000),
    Color(0x00FFFFFF),
  ];
  static const spineStops = <double>[0, 0.014, 0.03, 0.06];

  /// Lớp phủ tối dưới chữ trên ảnh bìa (badge, nhãn).
  static const scrim = Color(0x66000000);

  /// Chữ và biểu tượng đặt trên nền màu chủ đạo của bìa (đầu trang chủ điện thoại).
  static const onHero = Color(0xFFFFFFFF);

  /// Thẻ đen giải thích phương thức thanh toán (màn thanh toán điện thoại).
  static const cardTop = Color(0xFF2B2B30);
  static const cardBottom = Color(0xFF0C0C0E);

  /// Chữ tối đặt trên nền [onHero] (nấc đang chọn của công tắc khu).
  static const onHeroInk = Color(0xFF1D1D1F);

  /// Màu phụ cho hình vẽ trên bìa.
  static const motif = <Color>[
    Color(0xFFB9472F),
    Color(0xFF6D5640),
    Color(0xFF5D7A5C),
    Color(0xFFC9B78F),
    Color(0xFF3A3632),
  ];
}

extension AppThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}

/// Bảng màu riêng của trang giới thiệu (`/`): nền trắng ngà, chữ đen, điểm nhấn cam, băng vàng chanh,
/// chip xanh dương / xanh lá — theo video tham chiếu (người dùng gửi 2026-10-23).
abstract final class LandingPalette {
  static const background = Color(0xFFF6F6F7);
  static const ink = Color(0xFF0E0E10);
  static const muted = Color(0xFFB9B9BF);
  static const text = Color(0xFF55555C);
  static const orange = Color(0xFFFF5B22);
  static const red = Color(0xFFC8321F);
  static const yellow = Color(0xFFE5F65A);
  static const pink = Color(0xFFD3125A);
  static const blue = Color(0xFF1F5BFF);
  static const green = Color(0xFF39B58A);
  static const card = Color(0xFFFFFFFF);
  static const white = Color(0xFFFFFFFF);
  static const white70 = Color(0xB3FFFFFF);
  static const white54 = Color(0x8AFFFFFF);
  static const white24 = Color(0x3DFFFFFF);
  static const black = Color(0xFF000000);
  static const shadow = Color(0x24000000);
  static const panel = Color(0xFFEDEDEF);
  static const blueSoft = Color(0xFF2E6BFF);
  static const darkPanel = Color(0xFF1B1B1F);
  static const orangeSoft = Color(0xFFFF7A3D);
}
