import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/widgets/app_image.dart';

/// Biên lai chuyển khoản của một yêu cầu rút tiền (SRS 8.1): người chuyển, thời điểm, số tiền, ảnh chứng từ.
class WithdrawalReceiptView extends StatelessWidget {
  const WithdrawalReceiptView({super.key, required this.receipt});

  final WithdrawalReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final c = context.appColors;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: c.secondaryText),
            ),
          ),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        row(l10n.receiptSender, receipt.senderName),
        row(l10n.receiptTime, formatDateTime(receipt.transferredAt)),
        row(l10n.receiptAmount, formatVnd(receipt.amount)),
        if (receipt.proofImageUrl.isEmpty)
          Text(
            l10n.receiptNoImage,
            style: text.bodySmall?.copyWith(color: c.tertiaryText),
          )
        else
          PhotoStrip(urls: [receipt.proofImageUrl], size: 160),
      ],
    );
  }
}

/// Tờ trượt hiện biên lai (dùng ở màn Admin và ví người bán).
Future<void> showReceiptSheet(BuildContext context, WithdrawalReceipt receipt) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sheet.l10n.receiptTitle, style: sheet.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            WithdrawalReceiptView(receipt: receipt),
          ],
        ),
      ),
    ),
  );
}
