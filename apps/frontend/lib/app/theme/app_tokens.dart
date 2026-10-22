import 'package:flutter/material.dart';

/// Design tokens — style Apple Books đã duyệt (`design-preview/png/apple-*.png`).
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
  static const sm = Radius.circular(7);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(14);
  static const pill = Radius.circular(999);

  static const card = BorderRadius.all(md);
  static const sidebar = BorderRadius.all(lg);
  static const item = BorderRadius.all(sm);
  static const chip = BorderRadius.all(pill);

  /// Bìa sách: gáy (trái) bo ít, mép (phải) bo hơn — như cuốn sách thật.
  static const poster = BorderRadius.only(
    topLeft: Radius.circular(2),
    bottomLeft: Radius.circular(2),
    topRight: Radius.circular(5),
    bottomRight: Radius.circular(5),
  );
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
}

abstract final class AppFonts {
  /// Tiêu đề trang, tên sách trên bìa.
  static const serif = 'Newsreader';

  /// Toàn bộ chữ giao diện.
  static const sans = 'BeVietnamPro';
}

/// Màu riêng của style Apple Books, ngoài ColorScheme.
/// Dùng: `context.appColors.sidebar`.
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
  });

  /// Nền sidebar desktop.
  final Color sidebar;

  /// Mục đang chọn trong sidebar / tab.
  final Color selected;
  final Color onSelected;

  /// Nền xen kẽ giữa các kệ trên mobile.
  final Color shelfAlt;

  /// Nền ô tìm kiếm, nút phụ, tab đang chọn trên mobile.
  final Color fill;
  final Color separator;
  final Color secondaryText;
  final Color tertiaryText;

  /// Badge "MỚI".
  final Color badgeNew;

  /// Đấu giá đang diễn ra, badge "ĐẤU GIÁ", đồng hồ.
  final Color live;
  final Color success;
  final Color warning;
  final Color info;

  /// Tab bar nổi trên mobile.
  final Color tabBar;
  final Color posterShadow;

  static const light = AppColors(
    sidebar: Color(0xFFF5F5F7),
    selected: Color(0xFF3A3A3C),
    onSelected: Color(0xFFFFFFFF),
    shelfAlt: Color(0xFFF5F5F6),
    fill: Color(0xFFECECEE),
    separator: Color(0xFFE5E5EA),
    secondaryText: Color(0xFF6E6E73),
    tertiaryText: Color(0xFFAEAEB2),
    badgeNew: Color(0xFF1A3A8F),
    live: Color(0xFFB3261E),
    success: Color(0xFF248A3D),
    warning: Color(0xFFB25000),
    info: Color(0xFF0A66D8),
    tabBar: Color(0xF5FAFAFA),
    posterShadow: Color(0x59000000),
  );

  static const dark = AppColors(
    sidebar: Color(0xFF2C2C2E),
    selected: Color(0xFFEBEBF0),
    onSelected: Color(0xFF1C1C1E),
    shelfAlt: Color(0xFF242426),
    fill: Color(0xFF3A3A3C),
    separator: Color(0xFF38383A),
    secondaryText: Color(0xFF98989D),
    tertiaryText: Color(0xFF636366),
    badgeNew: Color(0xFF5E8BFF),
    live: Color(0xFFFF6961),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    info: Color(0xFF64A8FF),
    tabBar: Color(0xF22C2C2E),
    posterShadow: Color(0x99000000),
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
    );
  }
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
