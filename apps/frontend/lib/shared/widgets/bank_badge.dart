import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Ô tròn màu thương hiệu ngân hàng với chữ viết tắt (tự vẽ, không dùng logo thật).
class BankBadge extends StatelessWidget {
  const BankBadge(this.bank, {super.key, this.size = 40});

  final String bank;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BankPalette.colorOf(bank),
      ),
      child: Text(
        BankPalette.codeOf(bank),
        maxLines: 1,
        style: context.textStyles.labelSmall?.copyWith(
          color: CoverPalette.onHero,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.27,
        ),
      ),
    );
  }
}
