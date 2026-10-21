import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/domain/book.dart';

class BookConditionBadge extends StatelessWidget {
  const BookConditionBadge(this.condition, {super.key});

  final BookCondition condition;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final (label, color) = switch (condition) {
      BookCondition.likeNew => (l10n.conditionLikeNew, colors.conditionGood),
      BookCondition.good => (l10n.conditionGood, colors.conditionGood),
      BookCondition.fair => (l10n.conditionFair, colors.conditionWorn),
      BookCondition.worn => (l10n.conditionWorn, colors.conditionWorn),
      BookCondition.unknown => (l10n.conditionUnknown, colors.conditionWorn),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.chip,
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
