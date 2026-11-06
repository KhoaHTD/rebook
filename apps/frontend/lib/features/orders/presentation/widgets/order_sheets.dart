import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/shared/widgets/form_widgets.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/orders/presentation/providers/orders_providers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/photo_picker.dart';
import 'package:book_marketplace/shared/widgets/sheets.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Yêu cầu trả hàng: mô tả + ảnh minh chứng (chỉ khi sách khác mô tả — SRS 4.4).
Future<(String, List<String>, bool)?> showReturnSheet(BuildContext context) {
  final l10n = context.l10n;
  final reason = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var photos = <String>[];
  var notReceived = false;
  return showAppSheet<(String, List<String>, bool)>(
    context,
    title: l10n.requestReturn,
    body: (c, setState) => Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hai loại: sách không đúng mô tả (cần ảnh) hoặc chưa nhận được hàng (không cần ảnh).
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: Text(l10n.returnTypeWrong),
                selected: !notReceived,
                onSelected: (_) => setState(() => notReceived = false),
              ),
              ChoiceChip(
                label: Text(l10n.returnTypeNotReceived),
                selected: notReceived,
                onSelected: (_) => setState(() => notReceived = true),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          RuleField(
            controller: reason,
            rule: Rules.reason,
            label: l10n.returnReason,
            minLines: 3,
            maxLines: 4,
            showCounter: true,
          ),
          if (!notReceived) ...[
            Text(l10n.returnPhotos, style: c.textStyles.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            PhotoPickerField(
              folder: 'returns',
              max: 5,
              onChanged: (urls) => photos = urls,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(c, (
                Rules.reason.value(reason.text),
                notReceived ? <String>[] : photos,
                notReceived,
              ));
            },
            child: Text(l10n.submit),
          ),
        ],
      ),
    ),
  );
}

/// Đánh giá 1–5 sao + nhận xét (mỗi đơn một lần — SRS 4.4).
Future<(int, String?)?> showReviewSheet(BuildContext context) {
  final l10n = context.l10n;
  final comment = TextEditingController();
  var stars = 5;
  return showAppSheet<(int, String?)>(
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
        RuleField(
          controller: comment,
          rule: Rules.review,
          label: l10n.reviewComment,
          minLines: 2,
          maxLines: 3,
          showCounter: true,
          onChanged: (_) => setState(() {}),
        ),
        FilledButton(
          onPressed: !Rules.review.isValid(comment.text)
              ? null
              : () => Navigator.pop(c, (
                  stars,
                  comment.text.trim().isEmpty
                      ? null
                      : Rules.review.value(comment.text),
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

/// Thanh toán hóa đơn đấu giá: giao tận nơi (chọn địa chỉ) hoặc nhận tại kho; trả bằng ví hoặc ZaloPay (SRS 6.6).
Future<InvoiceChoice?> showPayInvoiceSheet(
  BuildContext context,
  WidgetRef ref,
  Order order,
) {
  final l10n = context.l10n;
  var pickup = false;
  var method = PaymentMethod.wallet;
  String? addressId;
  return showAppSheet<InvoiceChoice>(
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
              selected: method == PaymentMethod.zalopay,
              title: l10n.payZalopay,
              subtitle: l10n.payZalopayHint,
              onTap: () => setState(() => method = PaymentMethod.zalopay),
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
