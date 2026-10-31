import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';

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

/// Ô nhập theo một [InputRule]: nhãn nằm trên khung, chữ mờ gợi ý trong ô (mất khi gõ), bộ lọc ký tự,
/// giới hạn độ dài và kiểm tra khi người dùng đã chạm vào ô (cũng chạy khi `Form.validate()`).
class RuleField extends StatelessWidget {
  const RuleField({
    super.key,
    required this.rule,
    this.label,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.obscure = false,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 1,
    this.autofillHints,
    this.textInputAction,
    this.showCounter = false,
    this.suffixIcon,
    this.bottom = AppSpacing.lg,
    this.validator,
  });

  final InputRule rule;

  /// null = không có nhãn phía trên (màn tự đặt nhãn).
  final String? label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscure;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  /// Hiện bộ đếm ký tự (ô nhiều dòng).
  final bool showCounter;
  final Widget? suffixIcon;
  final double bottom;

  /// Kiểm tra thêm sau luật (vd. nhập lại mật khẩu phải khớp); trả về câu lỗi hoặc null.
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final base = rule.validator(l10n);
    final field = TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      minLines: minLines,
      maxLines: obscure ? 1 : maxLines,
      keyboardType: rule.keyboard,
      inputFormatters: rule.formatters,
      textCapitalization: rule.capitalization,
      maxLength: rule.maxLength,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: rule.hint(l10n),
        counterText: showCounter ? null : '',
        suffixIcon: suffixIcon,
      ),
      validator: (v) => base(v) ?? validator?.call(v),
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
    return label == null
        ? Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: field,
          )
        : LabeledField(label: label!, bottom: bottom, child: field);
  }
}
