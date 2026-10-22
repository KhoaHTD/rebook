import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Theme style Apple Books. Cỡ chữ theo mockup đã duyệt:
/// - displaySmall: tiêu đề trang desktop (serif 34, đậm)
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
          seedColor: c.selected,
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

    const sans = AppFonts.sans;
    const serif = AppFonts.serif;
    final text = TextTheme(
      displaySmall: TextStyle(
        fontFamily: serif,
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.3,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: serif,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: sans,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontFamily: sans,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontFamily: sans,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontFamily: sans,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: sans,
        fontSize: 16,
        height: 1.5,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: sans,
        fontSize: 14.5,
        height: 1.45,
        color: ink,
      ),
      bodySmall: TextStyle(
        fontFamily: sans,
        fontSize: 12,
        height: 1.35,
        color: c.secondaryText,
      ),
      labelLarge: TextStyle(
        fontFamily: sans,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontFamily: sans,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      labelSmall: TextStyle(
        fontFamily: sans,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: ink,
      ),
    );

    const pill = StadiumBorder();
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: sans,
      textTheme: text,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      dividerColor: c.separator,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
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
          backgroundColor: ink,
          foregroundColor: surface,
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
          foregroundColor: c.info,
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
          borderSide: BorderSide(color: c.selected, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: BorderSide(color: c.live),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.fill,
        selectedColor: c.selected,
        labelStyle: text.labelMedium,
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
        backgroundColor: c.selected,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onSelected),
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
