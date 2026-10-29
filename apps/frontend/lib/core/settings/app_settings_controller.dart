import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_controller.g.dart';

/// Lựa chọn giao diện. Mặc định [light] — style Liquid Glass đã duyệt là nền sáng.
enum ThemePref { light, dark, system }

/// Nút điều hướng nổi nằm bên nào của màn hình (sidebar trượt ra từ cùng phía).
enum NavSide { left, right }

/// Tuỳ chọn giao diện của người dùng (theme, ngôn ngữ, vị trí nút điều hướng).
class AppSettings {
  const AppSettings({
    this.theme = ThemePref.light,
    this.locale = const Locale('vi'),
    this.navSide = NavSide.left,
  });

  final ThemePref theme;

  /// Mặc định tiếng Việt (chợ sách Việt). `null` = theo ngôn ngữ thiết bị.
  final Locale? locale;

  /// Vị trí nút điều hướng nổi (kéo nút sang bên kia hoặc chọn trong Cài đặt).
  final NavSide navSide;

  ThemeMode get themeMode => switch (theme) {
    ThemePref.light => ThemeMode.light,
    ThemePref.dark => ThemeMode.dark,
    ThemePref.system => ThemeMode.system,
  };

  AppSettings copyWith({ThemePref? theme, Locale? locale, NavSide? navSide}) =>
      AppSettings(
        theme: theme ?? this.theme,
        locale: locale ?? this.locale,
        navSide: navSide ?? this.navSide,
      );
}

@Riverpod(keepAlive: true)
class AppSettingsController extends _$AppSettingsController {
  @override
  AppSettings build() => const AppSettings();

  void setTheme(ThemePref theme) => state = state.copyWith(theme: theme);

  /// null = theo ngôn ngữ thiết bị.
  void setLocale(Locale? locale) => state = AppSettings(
    theme: state.theme,
    locale: locale,
    navSide: state.navSide,
  );

  void setNavSide(NavSide side) => state = state.copyWith(navSide: side);
}
