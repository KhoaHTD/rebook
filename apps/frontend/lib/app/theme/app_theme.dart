import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Theme style Liquid Glass (chữ SF trên iPhone/Mac, Inter trên web/Android). Cỡ chữ:
/// - displaySmall: tiêu đề trang desktop (34, đậm)
/// - headlineSmall: tiêu đề trang mobile / tiêu đề kệ (sans 22, rất đậm)
/// - titleMedium: tiêu đề khối (sans 17, đậm)
/// - titleSmall: tên sách dưới poster (sans 13, đậm vừa)
/// - bodyMedium: chữ thường 15 · bodySmall: dòng meta 12 (màu phụ)
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppColors.light);
  static ThemeData dark() => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final isLight = brightness == Brightness.light;
    final ink = isLight ? const Color(0xFF1D1D1F) : const Color(0xFFF5F5F7);
    final surface = isLight ? Colors.white : const Color(0xFF1C1C1E);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.tint,
          brightness: brightness,
        ).copyWith(
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: c.secondaryText,
          primary: ink,
          onPrimary: surface,
          secondary: c.secondaryText,
          surfaceContainerLowest: surface,
          surfaceContainerLow: c.sidebar,
          surfaceContainer: c.sidebar,
          surfaceContainerHigh: c.fill,
          surfaceContainerHighest: c.fill,
          outline: c.tertiaryText,
          outlineVariant: c.separator,
          error: c.live,
        );

    final family = AppFonts.family;
    TextStyle t(
      double size,
      FontWeight weight,
      double height,
      double track, [
      Color? color,
    ]) => TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: track,
      color: color ?? ink,
    );
    final text = TextTheme(
      displaySmall: t(34, FontWeight.w700, 1.1, -0.9),
      headlineMedium: t(28, FontWeight.w700, 1.12, -0.6),
      headlineSmall: t(22, FontWeight.w700, 1.18, -0.45),
      titleLarge: t(19, FontWeight.w700, 1.2, -0.35),
      titleMedium: t(16, FontWeight.w600, 1.3, -0.2),
      titleSmall: t(13, FontWeight.w600, 1.3, -0.08),
      bodyLarge: t(16, FontWeight.w400, 1.47, -0.2),
      bodyMedium: t(14.5, FontWeight.w400, 1.42, -0.12),
      bodySmall: t(12, FontWeight.w400, 1.35, 0, c.secondaryText),
      labelLarge: t(14.5, FontWeight.w600, 1.2, -0.12),
      labelMedium: t(12, FontWeight.w500, 1.2, 0),
      labelSmall: t(10.5, FontWeight.w700, 1.2, 0.2),
    );

    const pill = StadiumBorder();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: family,
      textTheme: text,
      // Trang và khung app trong suốt: nền màu loang (AmbientBackground) nằm phía sau.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: surface,
      dividerColor: c.separator,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
      ),
      dividerTheme: DividerThemeData(
        color: c.separator,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: c.sidebar,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.tint,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: pill,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: c.fill,
          side: BorderSide.none,
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: pill,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.tint,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.fill,
        isDense: true,
        hintStyle: text.bodyMedium?.copyWith(color: c.secondaryText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: BorderSide(color: c.tint, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: BorderSide(color: c.live),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.fill,
        selectedColor: c.selected,
        // FilterChip không dùng secondaryLabelStyle → đổi màu chữ theo trạng thái chọn.
        labelStyle: text.labelMedium?.copyWith(
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? c.onSelected
                : text.labelMedium?.color ?? ink,
          ),
        ),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: c.onSelected),
        side: BorderSide.none,
        shape: pill,
        showCheckmark: false,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: ink,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: surface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: ink,
        linearTrackColor: c.fill,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        textStyle: text.bodyMedium,
      ),
    );
  }
}
