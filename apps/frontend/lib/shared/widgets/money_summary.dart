import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Một dòng tiền: nhãn bên trái, số tiền bên phải. [strong]: dòng tổng.
class MoneyLine extends StatelessWidget {
  const MoneyLine(this.label, this.amount, {super.key, this.strong = false});

  final String label;
  final int amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong
        ? context.textStyles.titleLarge
        : context.textStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: strong
                  ? style
                  : style?.copyWith(color: context.appColors.secondaryText),
            ),
          ),
          PriceText(amount, style: style, strong: strong),
        ],
      ),
    );
  }
}

/// Tóm tắt tiền (tạm tính, ship, phí khác, tổng) + nút hành động — cột phải trên desktop.
class SummaryPanel extends StatelessWidget {
  const SummaryPanel({
    super.key,
    required this.subtotal,
    required this.shipping,
    required this.total,
    this.extra = const [],
    this.action,
  });

  final int subtotal;
  final int shipping;
  final int total;

  /// Dòng phụ: (nhãn, số tiền) — vd phí người mua, trừ cọc (số âm).
  final List<(String, int)> extra;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InfoPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MoneyLine(l10n.subtotal, subtotal),
          MoneyLine(l10n.shippingFee, shipping),
          for (final (label, amount) in extra) MoneyLine(label, amount),
          Divider(color: context.appColors.separator, height: AppSpacing.lg),
          MoneyLine(l10n.total, total, strong: true),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
