import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/domain/book.dart';

/// Nhãn tình trạng sách theo thang chuẩn.
String conditionLabel(BuildContext context, BookCondition c) {
  final l10n = context.l10n;
  return switch (c) {
    BookCondition.brandNew => l10n.conditionNew,
    BookCondition.likeNew => l10n.conditionLikeNew,
    BookCondition.veryGood => l10n.conditionVeryGood,
    BookCondition.good => l10n.conditionGood,
    BookCondition.acceptable => l10n.conditionAcceptable,
    BookCondition.unknown => l10n.conditionUnknown,
  };
}

/// Mô tả ngắn của từng mức tình trạng (dùng khi chọn tình trạng lúc đăng bán, lọc).
String conditionDescription(BuildContext context, BookCondition c) {
  final l10n = context.l10n;
  return switch (c) {
    BookCondition.brandNew => l10n.conditionNewDesc,
    BookCondition.likeNew => l10n.conditionLikeNewDesc,
    BookCondition.veryGood => l10n.conditionVeryGoodDesc,
    BookCondition.good => l10n.conditionGoodDesc,
    BookCondition.acceptable => l10n.conditionAcceptableDesc,
    BookCondition.unknown => l10n.conditionUnknown,
  };
}

class BookConditionBadge extends StatelessWidget {
  const BookConditionBadge(this.condition, {super.key});

  final BookCondition condition;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = switch (condition) {
      BookCondition.brandNew ||
      BookCondition.likeNew ||
      BookCondition.veryGood => colors.conditionGood,
      _ => colors.conditionWorn,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        conditionLabel(context, condition),
        style: context.textStyles.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
