import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_controller.g.dart';

/// Tuỳ chọn giao diện của người dùng (theme, ngôn ngữ).
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;

  /// `null` = theo ngôn ngữ thiết bị.
  final Locale? locale;

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale}) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
  );
}

@Riverpod(keepAlive: true)
class AppSettingsController extends _$AppSettingsController {
  @override
  AppSettings build() => const AppSettings();

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setLocale(Locale locale) => state = state.copyWith(locale: locale);
}
