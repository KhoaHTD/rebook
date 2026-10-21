import 'package:flutter/material.dart';

/// Design tokens. Widget KHÔNG hardcode số đo / màu — luôn lấy từ đây hoặc từ Theme.
abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadius {
  static const sm = Radius.circular(6);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(20);

  static const card = BorderRadius.all(md);
  static const chip = BorderRadius.all(sm);
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
}

/// Bảng màu thương hiệu: tông giấy cũ + bìa da.
abstract final class AppPalette {
  static const leather = Color(0xFF7A4E2D);
  static const ink = Color(0xFF2B2420);
  static const paper = Color(0xFFFAF6EF);
  static const moss = Color(0xFF4F6B3A);
  static const ember = Color(0xFFC2410C);
}

/// Màu ngữ nghĩa không có sẵn trong ColorScheme.
/// Dùng: `Theme.of(context).extension<AppColors>()!.auctionLive`
/// hoặc gọn hơn: `context.appColors.auctionLive`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.auctionLive,
    required this.onAuctionLive,
    required this.priceHighlight,
    required this.conditionGood,
    required this.conditionWorn,
  });

  final Color auctionLive;
  final Color onAuctionLive;
  final Color priceHighlight;
  final Color conditionGood;
  final Color conditionWorn;

  static const light = AppColors(
    auctionLive: AppPalette.ember,
    onAuctionLive: Color(0xFFFFFFFF),
    priceHighlight: AppPalette.leather,
    conditionGood: AppPalette.moss,
    conditionWorn: Color(0xFF8A7F72),
  );

  static const dark = AppColors(
    auctionLive: Color(0xFFFB923C),
    onAuctionLive: Color(0xFF1C1917),
    priceHighlight: Color(0xFFE7B98F),
    conditionGood: Color(0xFF9BC27F),
    conditionWorn: Color(0xFFB4A99C),
  );

  @override
  AppColors copyWith({
    Color? auctionLive,
    Color? onAuctionLive,
    Color? priceHighlight,
    Color? conditionGood,
    Color? conditionWorn,
  }) {
    return AppColors(
      auctionLive: auctionLive ?? this.auctionLive,
      onAuctionLive: onAuctionLive ?? this.onAuctionLive,
      priceHighlight: priceHighlight ?? this.priceHighlight,
      conditionGood: conditionGood ?? this.conditionGood,
      conditionWorn: conditionWorn ?? this.conditionWorn,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      auctionLive: Color.lerp(auctionLive, other.auctionLive, t)!,
      onAuctionLive: Color.lerp(onAuctionLive, other.onAuctionLive, t)!,
      priceHighlight: Color.lerp(priceHighlight, other.priceHighlight, t)!,
      conditionGood: Color.lerp(conditionGood, other.conditionGood, t)!,
      conditionWorn: Color.lerp(conditionWorn, other.conditionWorn, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
