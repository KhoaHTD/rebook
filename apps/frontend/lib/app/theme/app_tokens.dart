import 'package:flutter/material.dart';

/// Design tokens. Widget KHÔNG hardcode số đo / màu — luôn lấy từ đây hoặc từ Theme.
///
/// Ngôn ngữ thiết kế: iOS 26 "Liquid Glass" (canvas "ReBook UI Redesign"):
/// nền trắng + nhóm xám nhạt, thanh điều khiển là khối kính nổi, nút viên thuốc,
/// màu nhấn cam đất chỉ dùng cho hành động chính.
abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;

  /// Khoảng trống dưới đáy nội dung để không bị thanh tab kính nổi che.
  static const floatingBarInset = 176.0;

  /// Khoảng trống dưới đáy khi màn chỉ có một thanh kính (không có thanh tab).
  static const bottomBarInset = 120.0;
}

abstract final class AppRadius {
  static const sm = Radius.circular(6);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(20);

  static const card = BorderRadius.all(md);
  static const chip = BorderRadius.all(sm);

  /// Bìa sách: góc gần vuông như sách thật.
  static const cover = BorderRadius.all(Radius.circular(4));

  /// Ô danh mục, thẻ nhỏ.
  static const tile = BorderRadius.all(Radius.circular(16));

  /// Nhóm danh sách kiểu iOS (inset grouped), thẻ lớn.
  static const group = BorderRadius.all(Radius.circular(24));

  /// Sheet bo góc đồng tâm với màn hình.
  static const sheet = BorderRadius.vertical(top: Radius.circular(40));

  /// Viên thuốc: luôn bo tròn hết chiều cao.
  static const pill = BorderRadius.all(Radius.circular(999));
}

abstract final class AppSizes {
  /// Vùng chạm tối thiểu.
  static const touch = 44.0;
  static const tabBarHeight = 64.0;
  static const accessoryHeight = 56.0;
  static const bidButtonHeight = 64.0;
  static const blur = 22.0;
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
}

/// Bảng màu gốc. Widget dùng qua `context.colors` / `context.appColors`,
/// trừ màu ô danh mục ([categoryTiles]) là dữ liệu trang trí.
abstract final class AppPalette {
  static const ember = Color(0xFFC2410C);
  static const emberDeep = Color(0xFF9A3412);
  static const emberBright = Color(0xFFFFB37A);
  static const live = Color(0xFFD70015);
  static const success = Color(0xFF248A3D);
  static const caution = Color(0xFFC93400);
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const ink = Color(0xFF1C1C1E);
  static const ink2 = Color(0xFF2C2C2E);
  static const label2 = Color(0xFF3C3C43);
  static const label3 = Color(0xFF6E6E73);
  static const label3Dark = Color(0xFF98989F);
  static const grouped = Color(0xFFF2F2F7);

  // Kiểu "Liquid Glass" và phòng đấu giá tối
  static const glassLight = Color(0x9EFAFAFC);
  static const glassDark = Color(0x9E1C1C1E);
  static const glassOnDark = Color(0x1FFFFFFF);
  static const fillLight = Color(0x1F767680);
  static const fillDark = Color(0x3D767680);
  static const separatorLight = Color(0x333C3C43);
  static const separatorDark = Color(0x40545458);
  static const shadow = Color(0x24000000);
  static const scrim = Color(0x33000000);
  static const positiveOnDark = Color(0xFF30D158);
  static const warningOnDark = Color(0xFFFF9F0A);
  static const dangerOnDark = Color(0xFFFF453A);
  static const roomTop = Color(0xFF7A5A3A);
  static const roomMid = Color(0xFF3B2416);
  static const roomBottom = Color(0xFF140C08);
  static const lotTop = Color(0xFF7A3528);
  static const lotBottom = Color(0xFF4E2019);
  static const collection = Color(0xFF6E1E2B);

  /// Ô "Duyệt theo thể loại" — chọn theo thứ tự.
  static const categoryTiles = [
    Color(0xFFC2410C),
    Color(0xFF1F5F8B),
    Color(0xFF2F7A4A),
    Color(0xFF5E4B8B),
  ];
}

/// Màu ngữ nghĩa không có sẵn trong ColorScheme.
/// Dùng: `context.appColors.live`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.auctionLive,
    required this.onAuctionLive,
    required this.priceHighlight,
    required this.conditionGood,
    required this.conditionWorn,
    required this.accentTint,
    required this.onAccentTint,
    required this.groupedBackground,
    required this.groupedCell,
    required this.labelSecondary,
    required this.labelTertiary,
    required this.separator,
    required this.fill,
    required this.glass,
    required this.shadow,
    required this.scrim,
    required this.success,
    required this.caution,
    required this.strongSurface,
    required this.onStrongSurface,
    required this.onStrongSurfaceMuted,
    required this.room,
    required this.lotHeader,
    required this.collection,
    required this.onDark,
    required this.onDarkMuted,
    required this.glassOnDark,
    required this.positiveOnDark,
    required this.warningOnDark,
    required this.dangerOnDark,
  });

  /// Huy hiệu LIVE, chấm đỏ.
  final Color auctionLive;
  final Color onAuctionLive;
  final Color priceHighlight;
  final Color conditionGood;
  final Color conditionWorn;

  /// Nền nhạt của chip đang chọn (màu nhấn 12%).
  final Color accentTint;
  final Color onAccentTint;

  /// Nền nhóm (sheet, trang Đăng bán) và ô bên trong.
  final Color groupedBackground;
  final Color groupedCell;
  final Color labelSecondary;
  final Color labelTertiary;
  final Color separator;

  /// Nền segmented control, nút phụ tròn.
  final Color fill;

  /// Màu phủ của khối kính (thanh tab, ô tìm kiếm, nút nổi).
  final Color glass;
  final Color shadow;
  final Color scrim;
  final Color success;
  final Color caution;

  /// Thẻ tối nổi bật (phiên đang diễn ra, nút "Bộ lọc").
  final Color strongSurface;
  final Color onStrongSurface;
  final Color onStrongSurfaceMuted;

  /// Nền phòng đấu giá (tối, ấm) và đầu trang lô — 3 / 2 điểm gradient.
  final List<Color> room;
  final List<Color> lotHeader;
  final Color collection;

  /// Chữ và kính trên nền tối.
  final Color onDark;
  final Color onDarkMuted;
  final Color glassOnDark;
  final Color positiveOnDark;
  final Color warningOnDark;
  final Color dangerOnDark;

  static const light = AppColors(
    auctionLive: AppPalette.live,
    onAuctionLive: AppPalette.white,
    priceHighlight: AppPalette.black,
    conditionGood: AppPalette.success,
    conditionWorn: AppPalette.label3,
    accentTint: Color(0x1FC2410C),
    onAccentTint: AppPalette.emberDeep,
    groupedBackground: AppPalette.grouped,
    groupedCell: AppPalette.white,
    labelSecondary: AppPalette.label2,
    labelTertiary: AppPalette.label3,
    separator: AppPalette.separatorLight,
    fill: AppPalette.fillLight,
    glass: AppPalette.glassLight,
    shadow: AppPalette.shadow,
    scrim: AppPalette.scrim,
    success: AppPalette.success,
    caution: AppPalette.caution,
    strongSurface: AppPalette.ink,
    onStrongSurface: AppPalette.white,
    onStrongSurfaceMuted: Color(0xFFAEAEB2),
    room: [AppPalette.roomTop, AppPalette.roomMid, AppPalette.roomBottom],
    lotHeader: [AppPalette.lotTop, AppPalette.lotBottom],
    collection: AppPalette.collection,
    onDark: AppPalette.white,
    onDarkMuted: Color(0xB3FFFFFF),
    glassOnDark: AppPalette.glassOnDark,
    positiveOnDark: AppPalette.positiveOnDark,
    warningOnDark: AppPalette.warningOnDark,
    dangerOnDark: AppPalette.dangerOnDark,
  );

  static const dark = AppColors(
    auctionLive: Color(0xFFFF453A),
    onAuctionLive: AppPalette.white,
    priceHighlight: AppPalette.white,
    conditionGood: AppPalette.positiveOnDark,
    conditionWorn: AppPalette.label3Dark,
    accentTint: Color(0x33FB923C),
    onAccentTint: AppPalette.emberBright,
    groupedBackground: AppPalette.black,
    groupedCell: AppPalette.ink,
    labelSecondary: Color(0xFFEBEBF5),
    labelTertiary: AppPalette.label3Dark,
    separator: AppPalette.separatorDark,
    fill: AppPalette.fillDark,
    glass: AppPalette.glassDark,
    shadow: Color(0x66000000),
    scrim: Color(0x66000000),
    success: AppPalette.positiveOnDark,
    caution: AppPalette.warningOnDark,
    strongSurface: AppPalette.ink2,
    onStrongSurface: AppPalette.white,
    onStrongSurfaceMuted: Color(0xFFAEAEB2),
    room: [AppPalette.roomTop, AppPalette.roomMid, AppPalette.roomBottom],
    lotHeader: [AppPalette.lotTop, AppPalette.lotBottom],
    collection: AppPalette.collection,
    onDark: AppPalette.white,
    onDarkMuted: Color(0xB3FFFFFF),
    glassOnDark: AppPalette.glassOnDark,
    positiveOnDark: AppPalette.positiveOnDark,
    warningOnDark: AppPalette.warningOnDark,
    dangerOnDark: AppPalette.dangerOnDark,
  );

  @override
  AppColors copyWith({Color? auctionLive, Color? accentTint, Color? glass}) {
    return AppColors(
      auctionLive: auctionLive ?? this.auctionLive,
      onAuctionLive: onAuctionLive,
      priceHighlight: priceHighlight,
      conditionGood: conditionGood,
      conditionWorn: conditionWorn,
      accentTint: accentTint ?? this.accentTint,
      onAccentTint: onAccentTint,
      groupedBackground: groupedBackground,
      groupedCell: groupedCell,
      labelSecondary: labelSecondary,
      labelTertiary: labelTertiary,
      separator: separator,
      fill: fill,
      glass: glass ?? this.glass,
      shadow: shadow,
      scrim: scrim,
      success: success,
      caution: caution,
      strongSurface: strongSurface,
      onStrongSurface: onStrongSurface,
      onStrongSurfaceMuted: onStrongSurfaceMuted,
      room: room,
      lotHeader: lotHeader,
      collection: collection,
      onDark: onDark,
      onDarkMuted: onDarkMuted,
      glassOnDark: glassOnDark,
      positiveOnDark: positiveOnDark,
      warningOnDark: warningOnDark,
      dangerOnDark: dangerOnDark,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> l(List<Color> a, List<Color> b) => [
      for (var i = 0; i < a.length; i++) c(a[i], b[i]),
    ];
    return AppColors(
      auctionLive: c(auctionLive, other.auctionLive),
      onAuctionLive: c(onAuctionLive, other.onAuctionLive),
      priceHighlight: c(priceHighlight, other.priceHighlight),
      conditionGood: c(conditionGood, other.conditionGood),
      conditionWorn: c(conditionWorn, other.conditionWorn),
      accentTint: c(accentTint, other.accentTint),
      onAccentTint: c(onAccentTint, other.onAccentTint),
      groupedBackground: c(groupedBackground, other.groupedBackground),
      groupedCell: c(groupedCell, other.groupedCell),
      labelSecondary: c(labelSecondary, other.labelSecondary),
      labelTertiary: c(labelTertiary, other.labelTertiary),
      separator: c(separator, other.separator),
      fill: c(fill, other.fill),
      glass: c(glass, other.glass),
      shadow: c(shadow, other.shadow),
      scrim: c(scrim, other.scrim),
      success: c(success, other.success),
      caution: c(caution, other.caution),
      strongSurface: c(strongSurface, other.strongSurface),
      onStrongSurface: c(onStrongSurface, other.onStrongSurface),
      onStrongSurfaceMuted: c(onStrongSurfaceMuted, other.onStrongSurfaceMuted),
      room: l(room, other.room),
      lotHeader: l(lotHeader, other.lotHeader),
      collection: c(collection, other.collection),
      onDark: c(onDark, other.onDark),
      onDarkMuted: c(onDarkMuted, other.onDarkMuted),
      glassOnDark: c(glassOnDark, other.glassOnDark),
      positiveOnDark: c(positiveOnDark, other.positiveOnDark),
      warningOnDark: c(warningOnDark, other.warningOnDark),
      dangerOnDark: c(dangerOnDark, other.dangerOnDark),
    );
  }
}

extension AppThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
