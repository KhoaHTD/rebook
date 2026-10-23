import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/money_summary.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Một nhóm trong giỏ: tên shop, các cuốn (poster nhỏ, tình trạng, giá, số lượng), tạm tính + ship.
class CartGroupView extends StatelessWidget {
  const CartGroupView({super.key, required this.group, this.onQuantity});

  final CartGroup group;

  /// null = chỉ xem (bước xác nhận đặt hàng).
  final void Function(CartItem item, int quantity)? onQuantity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => context.go(Routes.shop(group.shop.id)),
          child: Row(
            children: [
              Icon(Icons.storefront_outlined, size: 18, color: c.secondaryText),
              const SizedBox(width: AppSpacing.sm),
              Text(group.shop.name, style: context.textStyles.titleMedium),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: c.tertiaryText,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in group.items)
          _ItemRow(item: item, onQuantity: onQuantity),
        Divider(color: c.separator),
        MoneyLine(l10n.subtotal, group.subtotal),
        MoneyLine(l10n.shippingFee, group.shippingFee),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, this.onQuantity});

  final CartItem item;
  final void Function(CartItem item, int quantity)? onQuantity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final book = item.listing.book;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.go(Routes.listing(item.listing.id)),
            child: BookPoster(
              title: book.title,
              author: book.author,
              coverUrl: book.coverUrl,
              seed: book.id,
              width: 64,
              shadow: false,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleMedium,
                ),
                Text(
                  '${book.author} · ${book.condition.label(l10n)}',
                  style: context.textStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                PriceText(item.listing.price),
              ],
            ),
          ),
          if (onQuantity != null)
            _Stepper(
              value: item.quantity,
              max: item.listing.stock,
              onChanged: (q) => onQuantity!(item, q),
              removeTooltip: l10n.removeItem,
            )
          else
            Text('× ${item.quantity}', style: context.textStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.removeTooltip,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;
  final String removeTooltip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: context.appColors.fill,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: value == 1 ? removeTooltip : null,
            icon: Icon(
              value == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
              size: 18,
            ),
            onPressed: () => onChanged(value - 1),
          ),
          Text('$value', style: context.textStyles.labelLarge),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_rounded, size: 18),
            onPressed: value >= max ? null : () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
