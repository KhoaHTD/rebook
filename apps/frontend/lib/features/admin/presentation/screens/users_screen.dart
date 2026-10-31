import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Tìm và khóa / mở khóa tài khoản (SRS 8.1).
class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final users = ref.watch(adminUsersProvider);
    final busy = ref.watch(adminActionsProvider).isLoading;

    Future<void> toggleLock(AppUser u) async {
      if (!u.locked &&
          !await confirmDialog(context, '${l10n.lock} ${u.fullName}?')) {
        return;
      }
      await ref.read(adminActionsProvider.notifier).run(
        (r) => r.setLocked(u.id, locked: !u.locked),
        [DataArea.profile],
      );
      if (!context.mounted) return;
      final error = ref.read(adminActionsProvider).error;
      if (error != null) showErrorSnack(context, error);
    }

    return AppPage(
      title: l10n.navUsers,
      showBack: false,
      onRefresh: () => ref.refresh(adminUsersProvider.future),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TextField(
            maxLength: 100,
            decoration: InputDecoration(
              counterText: '',
              hintText: l10n.searchUsers,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onSubmitted: (q) => ref.read(userQueryProvider.notifier).set(q),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: users,
          onRetry: () => ref.invalidate(adminUsersProvider),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.person_search_outlined,
                  title: l10n.noResults,
                )
              : InfoPanel(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    children: [
                      for (final (i, u) in list.indexed) ...[
                        if (i > 0)
                          Divider(height: 1, indent: 72, color: c.separator),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: c.fill,
                            child: Text(
                              u.fullName.isEmpty
                                  ? '?'
                                  : u.fullName.characters.first,
                              style: context.textStyles.titleMedium,
                            ),
                          ),
                          title: Text(u.fullName),
                          subtitle: Text(u.email),
                          trailing: Wrap(
                            spacing: AppSpacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (u.role != UserRole.user)
                                StatusPill(
                                  u.role == UserRole.admin
                                      ? l10n.adminRole
                                      : l10n.staffRole,
                                  tone: StatusTone.info,
                                ),
                              if (u.locked)
                                StatusPill(
                                  l10n.locked,
                                  tone: StatusTone.danger,
                                ),
                              if (u.role == UserRole.user)
                                OutlinedButton(
                                  onPressed: busy ? null : () => toggleLock(u),
                                  child: Text(
                                    u.locked ? l10n.unlock : l10n.lock,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
