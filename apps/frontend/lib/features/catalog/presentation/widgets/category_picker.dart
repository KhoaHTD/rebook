import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';

/// Bảng chọn thể loại hai cấp: nhóm cha bấm để xổ ra các thể loại con, mỗi dòng ghi số cuốn đang bán.
/// Thể loại chưa có sách bị ẩn (trừ thể loại đang chọn). Trả về `(id: …)`; `id` null nghĩa là "Tất cả thể loại";
/// đóng bảng mà không chọn thì trả về null.
Future<({String? id})?> showCategoryPicker(
  BuildContext context, {
  required List<Category> categories,
  required Map<String, int> counts,
  String? selectedId,
}) => showModalBottomSheet<({String? id})>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (sheet) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(sheet).height * 0.82,
    ),
    child: _CategoryPicker(
      categories: categories,
      counts: counts,
      selectedId: selectedId,
    ),
  ),
);

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.counts,
    required this.selectedId,
  });

  final List<Category> categories;
  final Map<String, int> counts;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final byId = {for (final x in categories) x.id: x};
    final selectedRoot = selectedId == null
        ? null
        : (byId[selectedId]?.parentId ?? selectedId);

    bool visible(Category x) => (counts[x.id] ?? 0) > 0 || x.id == selectedId;

    Widget countText(String id) => Text(
      '${counts[id] ?? 0}',
      style: text.labelMedium?.copyWith(color: c.secondaryText),
    );

    Widget row({
      required String label,
      required String? id,
      required int? count,
      bool indent = false,
      bool bold = false,
    }) {
      final on = selectedId == id;
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: indent ? 40 : 20, right: 20),
        title: Text(
          label,
          style: text.bodyLarge?.copyWith(
            fontWeight: on || bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        trailing: on
            ? Icon(Icons.check_rounded, color: c.tint)
            : (count == null ? null : countText(id ?? '')),
        onTap: () => Navigator.pop(context, (id: id)),
      );
    }

    final roots = [
      for (final x in categories)
        if (x.parentId == null && visible(x)) x,
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(l10n.pickCategoryTitle, style: text.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                row(label: l10n.pickCategoryAllBooks, id: null, count: null),
                for (final root in roots)
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: PageStorageKey(root.id),
                      initiallyExpanded: selectedRoot == root.id,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                      title: Text(
                        root.name,
                        style: text.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        l10n.exploreBookCount(counts[root.id] ?? 0),
                        style: text.bodySmall?.copyWith(color: c.secondaryText),
                      ),
                      children: [
                        row(
                          label: l10n.allCategories,
                          id: root.id,
                          count: counts[root.id] ?? 0,
                          indent: true,
                          bold: true,
                        ),
                        for (final child in categories)
                          if (child.parentId == root.id && visible(child))
                            row(
                              label: child.name,
                              id: child.id,
                              count: counts[child.id] ?? 0,
                              indent: true,
                            ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
