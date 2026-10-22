import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_theme.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';

/// Hỏi giá tối đa tự trả. Trả về số tiền (VND) hoặc null nếu huỷ.
Future<int?> showMaxBidSheet(
  BuildContext context, {
  required int minimum,
  required int suggested,
  int? limit,
}) {
  // Phòng đấu giá đổi chữ sang màu trắng cho nền tối; sheet nền sáng phải dùng lại theme gốc.
  final base = Theme.of(context).brightness == Brightness.dark
      ? AppTheme.dark()
      : AppTheme.light();
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: base.bottomSheetTheme.backgroundColor,
    builder: (_) => Theme(
      data: base,
      child: _MaxBidSheet(
        minimum: minimum,
        suggested: limit == null ? suggested : suggested.clamp(minimum, limit),
        limit: limit,
      ),
    ),
  );
}

class _MaxBidSheet extends StatefulWidget {
  const _MaxBidSheet({
    required this.minimum,
    required this.suggested,
    this.limit,
  });

  final int minimum;
  final int suggested;
  final int? limit;

  @override
  State<_MaxBidSheet> createState() => _MaxBidSheetState();
}

class _MaxBidSheetState extends State<_MaxBidSheet> {
  late final _controller = TextEditingController(text: '${widget.suggested}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < widget.minimum) {
      setState(() => _error = l10n.maxBidTooLow(formatVnd(widget.minimum)));
      return;
    }
    if (widget.limit != null && value > widget.limit!) {
      setState(() => _error = l10n.overBidLimit);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  l10n.maxBidTitle,
                  textAlign: TextAlign.center,
                  style: context.textStyles.titleMedium,
                ),
              ),
              IconButton.filled(
                tooltip: l10n.confirm,
                onPressed: _submit,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: context.textStyles.headlineSmall,
            decoration: InputDecoration(
              fillColor: colors.groupedCell,
              suffixText: '₫',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.maxBidExplain(
              formatVnd(widget.minimum),
              widget.limit == null ? '—' : formatVnd(widget.limit!),
            ),
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.labelTertiary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
