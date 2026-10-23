import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Khung chung của các bảng trượt: tiêu đề + nội dung + nút xác nhận.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext, StateSetter) body,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  builder: (c) => StatefulBuilder(
    builder: (c, setState) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(c).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: c.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            body(c, setState),
          ],
        ),
      ),
    ),
  ),
);

/// Hỏi xác nhận có / không.
Future<bool> confirmDialog(BuildContext context, String question) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      content: Text(question),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Chọn lý do hủy. [reasons]: chuỗi "a|b|c" trong file dịch.
Future<String?> showCancelSheet(
  BuildContext context,
  String reasons, {
  String? title,
}) {
  final l10n = context.l10n;
  String? picked;
  return showAppSheet<String>(
    context,
    title: title ?? l10n.cancelReason,
    body: (c, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in reasons.split('|'))
          SelectTile(
            selected: picked == r,
            title: r,
            onTap: () => setState(() => picked = r),
          ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: picked == null ? null : () => Navigator.pop(c, picked),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
}

/// Nhập một dòng chữ (mã vận đơn, ghi chú…). [optional]: cho phép để trống → trả về ''.
Future<String?> showTextSheet(
  BuildContext context, {
  required String title,
  required String label,
  String? hint,
  bool optional = false,
  int lines = 1,
}) {
  final l10n = context.l10n;
  final controller = TextEditingController();
  return showAppSheet<String>(
    context,
    title: title,
    body: (c, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hint != null) ...[
          Text(hint, style: c.textStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
        ],
        TextField(
          controller: controller,
          autofocus: true,
          minLines: lines,
          maxLines: lines == 1 ? 1 : lines + 2,
          decoration: InputDecoration(labelText: label),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: !optional && controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(c, controller.text.trim()),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
}

/// Nhập một số tiền. [max]: chặn trên (vd. giá sàn đề nghị ≤ mức thấp của ước tính).
Future<int?> showAmountSheet(
  BuildContext context, {
  required String title,
  required String label,
  String? hint,
  int? initial,
  int min = 1000,
  int? max,
}) {
  final l10n = context.l10n;
  final controller = TextEditingController(text: initial?.toString());
  return showAppSheet<int>(
    context,
    title: title,
    body: (c, setState) {
      final v = int.tryParse(controller.text);
      final ok = v != null && v >= min && (max == null || v <= max);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[
            Text(hint, style: c.textStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: label),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: ok ? () => Navigator.pop(c, v) : null,
            child: Text(l10n.confirm),
          ),
        ],
      );
    },
  );
}
