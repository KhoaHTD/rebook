import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/orders/presentation/providers/orders_providers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/photo_picker.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Khung chung của các bảng trượt: tiêu đề + nội dung + nút xác nhận.
Future<T?> _sheet<T>(
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
Future<String?> showCancelSheet(BuildContext context, String reasons) {
  final l10n = context.l10n;
  String? picked;
  return _sheet<String>(
    context,
    title: l10n.cancelReason,
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
          onPressed: () => picked == null ? null : Navigator.pop(c, picked),
          child: Text(l10n.confirm),
        ),
      ],
    ),
  );
}

/// Yêu cầu trả hàng: mô tả + ảnh minh chứng (chỉ khi sách khác mô tả — SRS 4.4).
Future<(String, List<String>)?> showReturnSheet(BuildContext context) {
  final l10n = context.l10n;
  final reason = TextEditingController();
  var photos = <String>[];
  return _sheet<(String, List<String>)>(
    context,
    title: l10n.requestReturn,
    body: (c, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: reason,
          maxLines: 4,
          decoration: InputDecoration(labelText: l10n.returnReason),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.returnPhotos, style: c.textStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        PhotoPickerField(
          folder: 'returns',
          max: 5,
          onChanged: (urls) => photos = urls,
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () {
            if (reason.text.trim().isEmpty) return;
            Navigator.pop(c, (reason.text.trim(), photos));
          },
          child: Text(l10n.submit),
        ),
      ],
    ),
  );
}

/// Đánh giá 1–5 sao + nhận xét (mỗi đơn một lần — SRS 4.4).
Future<(int, String?)?> showReviewSheet(BuildContext context) {
  final l10n = context.l10n;
  final comment = TextEditingController();
  var stars = 5;
  return _sheet<(int, String?)>(
    context,
    title: l10n.writeReview,
    body: (c, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                iconSize: 36,
                icon: Icon(
                  i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: c.appColors.warning,
                ),
                onPressed: () => setState(() => stars = i),
              ),
          ],
        ),
        TextField(
          controller: comment,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.reviewComment),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => Navigator.pop(c, (
            stars,
            comment.text.trim().isEmpty ? null : comment.text.trim(),
          )),
          child: Text(l10n.submit),
        ),
      ],
    ),
  );
}

/// Lựa chọn khi thanh toán hóa đơn lô thắng.
typedef InvoiceChoice = ({
  PaymentMethod method,
  String? addressId,
  bool pickup,
});

/// Thanh toán hóa đơn đấu giá: giao tận nơi (chọn địa chỉ) hoặc nhận tại kho; trả bằng ví hoặc VNPay (SRS 6.6).
Future<InvoiceChoice?> showPayInvoiceSheet(
  BuildContext context,
  WidgetRef ref,
  Order order,
) {
  final l10n = context.l10n;
  var pickup = false;
  var method = PaymentMethod.wallet;
  String? addressId;
  return _sheet<InvoiceChoice>(
    context,
    title: l10n.choosePayment,
    body: (c, setState) => Consumer(
      builder: (c, ref, _) {
        final addresses =
            ref.watch(orderAddressesProvider).value ?? const <Address>[];
        final wallet = ref.watch(orderWalletProvider).value;
        addressId ??=
            addresses.where((a) => a.isDefault).firstOrNull?.id ??
            addresses.firstOrNull?.id;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectTile(
              selected: !pickup,
              title: l10n.shipToMe,
              onTap: () => setState(() => pickup = false),
            ),
            SelectTile(
              selected: pickup,
              title: l10n.pickupAtWarehouse,
              onTap: () => setState(() => pickup = true),
            ),
            if (!pickup)
              for (final a in addresses)
                SelectTile(
                  selected: a.id == addressId,
                  title: '${a.receiver} · ${a.phone}',
                  subtitle: a.oneLine,
                  onTap: () => setState(() => addressId = a.id),
                ),
            const SizedBox(height: AppSpacing.md),
            SelectTile(
              selected: method == PaymentMethod.wallet,
              title: l10n.payWallet,
              subtitle: l10n.payWalletHint(formatVnd(wallet?.available ?? 0)),
              onTap: () => setState(() => method = PaymentMethod.wallet),
            ),
            SelectTile(
              selected: method == PaymentMethod.vnpay,
              title: l10n.payVnpay,
              subtitle: l10n.payVnpayHint,
              onTap: () => setState(() => method = PaymentMethod.vnpay),
            ),
            const SizedBox(height: AppSpacing.md),
            PriceText(order.total, style: c.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: !pickup && addressId == null
                  ? null
                  : () => Navigator.pop(c, (
                      method: method,
                      addressId: pickup ? null : addressId,
                      pickup: pickup,
                    )),
              child: Text(l10n.payNow),
            ),
          ],
        );
      },
    ),
  );
}
