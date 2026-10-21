import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';

/// Hiển thị giá VND với style thống nhất.
class PriceText extends StatelessWidget {
  const PriceText(this.amount, {super.key, this.style});

  final int amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.textStyles.titleMedium;
    return Text(
      formatVnd(amount),
      style: base?.copyWith(
        color: context.appColors.priceHighlight,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
