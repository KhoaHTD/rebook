import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/glass_menu.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Cây danh mục 2 cấp: thêm, sửa, xóa (SRS 8.1).
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  /// Báo lỗi (nếu có) sau một thao tác ghi.
  void _reportError(BuildContext context, WidgetRef ref) {
    if (!context.mounted) return;
    final error = ref.read(adminActionsProvider).error;
    if (error != null) showErrorSnack(context, error);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    List<Category> all, [
    Category? c,
  ]) async {
    final l10n = context.l10n;
    final name = TextEditingController(text: c?.name);
    String? parent = c?.parentId;
    final ok = await showAppSheet<bool>(
      context,
      title: c == null ? l10n.addCategory : l10n.edit,
      body: (sheet, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.categoryName),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          GlassDropdownField<String?>(
            value: parent,
            label: l10n.parentCategory,
            items: [
              GlassMenuItem<String?>(value: null, label: l10n.noParent),
              for (final p in all.where(
                (x) => x.parentId == null && x.id != c?.id,
              ))
                GlassMenuItem<String?>(value: p.id, label: p.name),
            ],
            onChanged: (v) => setState(() => parent = v),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: name.text.trim().isEmpty
                ? null
                : () => Navigator.pop(sheet, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final text = name.text.trim();
    name.dispose();
    if (ok != true || text.isEmpty || !context.mounted) return;
    await ref.read(adminActionsProvider.notifier).run(
      (r) => r.saveCategory(c?.id, text, parent),
      [DataArea.listings],
    );
    if (context.mounted) _reportError(context, ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sep = context.appColors.separator;
    final cats = ref.watch(adminCategoriesProvider);

    Widget tile(
      List<Category> all,
      Category c, {
      bool child = false,
    }) => ListTile(
      contentPadding: EdgeInsets.only(
        left: child ? AppSpacing.xxl : AppSpacing.md,
        right: AppSpacing.sm,
      ),
      leading: Icon(
        child ? Icons.subdirectory_arrow_right_rounded : Icons.folder_outlined,
      ),
      title: Text(c.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context, ref, all, c),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              if (await confirmDialog(context, '${l10n.delete} ${c.name}?') &&
                  context.mounted) {
                await ref.read(adminActionsProvider.notifier).run(
                  (r) => r.deleteCategory(c.id),
                  [DataArea.listings],
                );
                if (context.mounted) _reportError(context, ref);
              }
            },
          ),
        ],
      ),
    );

    return AppPage(
      title: l10n.navCategories,
      showBack: false,
      onRefresh: () => ref.refresh(adminCategoriesProvider.future),
      actions: [
        HeaderAction(
          icon: Icons.add_rounded,
          label: l10n.addCategory,
          onPressed: () =>
              _edit(context, ref, cats.value ?? const <Category>[]),
        ),
      ],
      children: [
        AsyncValueView(
          value: cats,
          onRetry: () => ref.invalidate(adminCategoriesProvider),
          data: (all) => ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: InfoPanel(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (final (i, root)
                      in all.where((c) => c.parentId == null).indexed) ...[
                    if (i > 0) Divider(height: 1, color: sep),
                    tile(all, root),
                    for (final c in all.where((c) => c.parentId == root.id))
                      tile(all, c, child: true),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
