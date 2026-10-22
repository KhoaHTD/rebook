import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Segmented control kiểu iOS: rãnh xám, ô đang chọn là viên trắng nổi.
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<(T value, String label)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        children: [
          for (final (value, label) in segments)
            Expanded(
              child: Semantics(
                selected: value == selected,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected
                          ? colors.groupedCell
                          : colors.groupedCell.withValues(alpha: 0),
                      borderRadius: AppRadius.pill,
                      boxShadow: value == selected
                          ? [
                              BoxShadow(
                                color: colors.shadow,
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      style: context.textStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
