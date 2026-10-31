import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Ô nhập có nhãn nằm hẳn phía trên khung (không đè lên viền): nhãn, khoảng cách nhỏ, rồi ô nhập.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.bottom = AppSpacing.lg,
  });

  final String label;
  final Widget child;

  /// Khoảng cách tới ô kế tiếp.
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textStyles.labelLarge?.copyWith(
              color: context.appColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Thanh nút ghim ở đáy trang có nền đặc và viền trên, để nội dung cuộn phía sau không lọt chữ lên nút.
class PinnedBar extends StatelessWidget {
  const PinnedBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.appColors.separator)),
      ),
      child: child,
    );
  }
}
