import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/settings/app_settings_controller.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/features/account/presentation/providers/account_providers.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Cài đặt giao diện (sáng / tối / theo hệ thống) và ngôn ngữ.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = TextEditingController();
    final next = TextEditingController();
    String? error;
    final ok = await showAppSheet<bool>(
      context,
      title: l10n.settingsPwdChange,
      body: (c, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RuleField(
            controller: current,
            rule: Rules.password,
            label: l10n.settingsPwdCurrent,
            obscure: true,
          ),
          RuleField(
            controller: next,
            rule: Rules.newPassword,
            label: l10n.settingsPwdNew,
            obscure: true,
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(c).colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: () {
              if (current.text.isEmpty || next.text.length < 8) {
                setState(() => error = l10n.settingsPwdTooShort);
                return;
              }
              Navigator.pop(c, true);
            },
            child: Text(l10n.submit),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final done = await ref
        .read(accountControllerProvider.notifier)
        .changePassword(current.text, next.text);
    if (!context.mounted) return;
    if (done) {
      showInfoSnack(context, l10n.settingsPwdChanged);
    } else {
      showErrorSnack(context, ref.read(accountControllerProvider).error!);
    }
  }

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
              const SizedBox(height: AppSpacing.lg),
              if (ref.watch(currentUserProvider) != null) ...[
                Text(
                  l10n.settingsPwdTitle,
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                InfoPanel(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: Text(l10n.settingsPwdChange),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: context.appColors.tertiaryText,
                    ),
                    onTap: () => _changePassword(context, ref),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(l10n.settingsIntro, style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              InfoPanel(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.slideshow_rounded),
                  title: Text(l10n.settingsIntroReplay),
                  subtitle: Text(l10n.settingsIntroReplayHint),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: context.appColors.tertiaryText,
                  ),
                  onTap: () => context.go(Routes.intro),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
