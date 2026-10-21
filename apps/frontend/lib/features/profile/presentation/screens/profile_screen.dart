import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/settings/app_settings_controller.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';

/// Tên ngôn ngữ luôn hiển thị bằng chính ngôn ngữ đó nên không đưa vào .arb.
const _languageNames = {'vi': 'Tiếng Việt', 'en': 'English'};

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(appSettingsControllerProvider);
    final settingsCtrl = ref.read(appSettingsControllerProvider.notifier);
    final currentLang =
        settings.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: MaxWidthBox(
        maxWidth: 640,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(l10n.settingsTheme, style: context.textStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settingsCtrl.setThemeMode(s.first),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.settingsLanguage, style: context.textStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<String>(
              segments: [
                for (final MapEntry(:key, :value) in _languageNames.entries)
                  ButtonSegment(value: key, label: Text(value)),
              ],
              selected: {currentLang},
              onSelectionChanged: (s) =>
                  settingsCtrl.setLocale(Locale(s.first)),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(sessionControllerProvider.notifier).signOut(),
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
            ),
          ],
        ),
      ),
    );
  }
}
