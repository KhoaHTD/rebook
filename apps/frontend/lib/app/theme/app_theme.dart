import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Theme theo ngôn ngữ thiết kế iOS 26 "Liquid Glass":
/// nền trắng / đen, chữ hệ thống, tiêu đề lớn đậm, nút viên thuốc, màu nhấn cam đất.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final app = isLight ? AppColors.light : AppColors.dark;
    final base = ColorScheme.fromSeed(
      seedColor: AppPalette.ember,
      brightness: brightness,
    );
    final scheme = base.copyWith(
      primary: AppPalette.ember,
      onPrimary: AppPalette.white,
      surface: isLight ? AppPalette.white : AppPalette.black,
      onSurface: isLight ? AppPalette.black : AppPalette.white,
      onSurfaceVariant: app.labelTertiary,
      surfaceContainerLowest: app.groupedCell,
      surfaceContainerLow: app.groupedBackground,
      surfaceContainer: app.groupedBackground,
      surfaceContainerHigh: app.groupedBackground,
      surfaceContainerHighest: app.groupedBackground,
      outline: app.labelTertiary,
      outlineVariant: app.separator,
    );

    final text = _textTheme(
      isLight
          ? Typography.material2021().black
          : Typography.material2021().white,
      scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [app],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: scheme.surface,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleMedium,
      ),
      dividerTheme: DividerThemeData(
        color: app.separator,
        thickness: 0.5,
        space: 0.5,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: app.groupedBackground,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.group),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: app.groupedBackground,
        hintStyle: TextStyle(color: app.labelTertiary),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.group,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: const StadiumBorder(),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 50),
          shape: const StadiumBorder(),
          side: BorderSide(color: app.separator),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.ember,
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: app.separator),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? app.success : app.fill,
        ),
        thumbColor: const WidgetStatePropertyAll(AppPalette.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: app.strongSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: app.onStrongSurface),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.tile),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: app.groupedBackground,
        showDragHandle: true,
        dragHandleColor: app.separator,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.ember,
      ),
    );
  }

  /// Thang chữ kiểu iOS: Large Title 34/800, Title 22/700, Headline 17/600, Body 16.
  static TextTheme _textTheme(TextTheme base, Color onSurface) {
    const tight = -0.2;
    return base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1,
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: tight,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: tight,
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 16,
            letterSpacing: tight,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 15,
            letterSpacing: tight,
          ),
          bodySmall: base.bodySmall?.copyWith(fontSize: 13, letterSpacing: 0),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        )
        .apply(bodyColor: onSurface, displayColor: onSurface);
  }
}
