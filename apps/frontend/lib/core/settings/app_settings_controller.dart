import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_controller.g.dart';

/// Lựa chọn giao diện. Mặc định [light] — style Apple Books đã duyệt là nền sáng.
enum ThemePref { light, dark, system }

/// Tuỳ chọn giao diện của người dùng (theme, ngôn ngữ).
class AppSettings {
  const AppSettings({this.theme = ThemePref.light, this.locale = const Locale('vi')});

  final ThemePref theme;

  /// Mặc định tiếng Việt (chợ sách Việt). `null` = theo ngôn ngữ thiết bị.
  final Locale? locale;

  ThemeMode get themeMode => switch (theme) {
    ThemePref.light => ThemeMode.light,
    ThemePref.dark => ThemeMode.dark,
    ThemePref.system => ThemeMode.system,
  };

  AppSettings copyWith({ThemePref? theme, Locale? locale}) =>
      AppSettings(theme: theme ?? this.theme, locale: locale ?? this.locale);
}

@Riverpod(keepAlive: true)
class AppSettingsController extends _$AppSettingsController {
  @override
  AppSettings build() => const AppSettings();

  void setTheme(ThemePref theme) => state = state.copyWith(theme: theme);

  /// null = theo ngôn ngữ thiết bị.
  void setLocale(Locale? locale) =>
      state = AppSettings(theme: state.theme, locale: locale);
}
