import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/settings/app_settings_controller.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Cài đặt giao diện (sáng / tối / theo hệ thống) và ngôn ngữ.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(appSettingsControllerProvider);
    final ctrl = ref.read(appSettingsControllerProvider.notifier);
    final lang = settings.locale?.languageCode;

    return AppPage(
      title: l10n.settings,
      showBack: true,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.settingsTheme, style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final (pref, label) in [
                (ThemePref.light, l10n.themeLight),
                (ThemePref.dark, l10n.themeDark),
                (ThemePref.system, l10n.themeSystem),
              ])
                SelectTile(
                  selected: settings.theme == pref,
                  title: label,
                  onTap: () => ctrl.setTheme(pref),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.settingsNavSide, style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final (side, label) in [
                (NavSide.left, l10n.navSideLeft),
                (NavSide.right, l10n.navSideRight),
              ])
                SelectTile(
                  selected: settings.navSide == side,
                  title: label,
                  onTap: () => ctrl.setNavSide(side),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.settingsLanguage,
                style: context.textStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final (code, label) in [
                ('vi', l10n.languageVi),
                ('en', l10n.languageEn),
                (null, l10n.languageSystem),
              ])
                SelectTile(
                  selected: lang == code,
                  title: label,
                  onTap: () =>
                      ctrl.setLocale(code == null ? null : Locale(code)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
