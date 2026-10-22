import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/catalog/domain/book_search_filter.dart';
import 'package:book_marketplace/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:book_marketplace/shared/domain/book.dart';
import 'package:book_marketplace/shared/widgets/book_condition_badge.dart';
import 'package:book_marketplace/shared/widgets/grouped_section.dart';

/// Sheet bộ lọc: huỷ (X) / áp dụng (✓) ở hai góc, tình trạng dạng danh sách tích, khoảng giá.
Future<void> showFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _FilterSheet(),
    );

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late BookSearchFilter _draft = ref.read(bookSearchProvider);
  late final _min = TextEditingController(
    text: _draft.minPrice?.toString() ?? '',
  );
  late final _max = TextEditingController(
    text: _draft.maxPrice?.toString() ?? '',
  );

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _apply() {
    ref
        .read(bookSearchProvider.notifier)
        .replace(
          _draft.copyWith(
            minPrice: int.tryParse(_min.text),
            maxPrice: int.tryParse(_max.text),
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    Widget priceField(TextEditingController c, String label) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: label,
            suffixText: '₫',
            filled: false,
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: l10n.cancel,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Text(
                  l10n.filters,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium,
                ),
              ),
              IconButton.filled(
                tooltip: l10n.apply,
                onPressed: _apply,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GroupedSection(
            header: l10n.condition,
            children: [
              for (final c in BookCondition.selectable)
                GroupedRow(
                  title: conditionLabel(context, c),
                  subtitle: conditionDescription(context, c),
                  trailing: _draft.conditions.contains(c)
                      ? Icon(Icons.check_rounded, color: context.colors.primary)
                      : null,
                  onTap: () => setState(() {
                    final next = {..._draft.conditions};
                    if (!next.remove(c)) next.add(c);
                    _draft = _draft.copyWith(conditions: next);
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GroupedSection(
            header: l10n.priceRange,
            footer: l10n.shippingNote,
            children: [
              Row(
                children: [
                  priceField(_min, l10n.priceFrom),
                  SizedBox(
                    height: 40,
                    child: VerticalDivider(color: colors.separator),
                  ),
                  priceField(_max, l10n.priceTo),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => setState(() {
              _draft = BookSearchFilter(query: _draft.query, sort: _draft.sort);
              _min.clear();
              _max.clear();
            }),
            child: Text(l10n.clearFilters),
          ),
        ],
      ),
    );
  }
}
