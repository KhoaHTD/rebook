import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/account/presentation/providers/account_providers.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/photo_picker.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Hồ sơ cá nhân: ảnh đại diện, họ tên, số điện thoại (email không đổi được).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return AppPage(
      title: context.l10n.profile,
      showBack: true,
      children: [
        AsyncValueView(
          value: profile,
          onRetry: () => ref.invalidate(profileProvider),
          data: (u) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _Form(user: u),
          ),
        ),
      ],
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.user});

  final AppUser user;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final _name = TextEditingController(text: widget.user.fullName);
  late final _phone = TextEditingController(text: widget.user.phone);
  late String? _avatar = widget.user.avatarUrl;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final ok = await ref
        .read(accountControllerProvider.notifier)
        .updateProfile(
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
          avatarUrl: _avatar,
        );
    if (!mounted) return;
    ok
        ? showInfoSnack(context, context.l10n.saved)
        : showErrorSnack(context, ref.read(accountControllerProvider).error!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(accountControllerProvider).isLoading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.avatar, style: context.textStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        PhotoPickerField(
          folder: 'avatars',
          max: 1,
          initial: [?_avatar],
          onChanged: (urls) => _avatar = urls.firstOrNull,
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledField(
          label: l10n.email,
          bottom: 0,
          child: TextField(
            enabled: false,
            controller: TextEditingController(text: widget.user.email),
            decoration: const InputDecoration(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledField(
          label: l10n.fullName,
          bottom: 0,
          child: TextField(
            controller: _name,
            decoration: const InputDecoration(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LabeledField(
          label: l10n.phone,
          bottom: 0,
          child: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: busy ? null : _save, child: Text(l10n.save)),
      ],
    );
  }
}
