import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/core/utils/input_rules.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/photo_picker.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';
import 'package:book_marketplace/shared/widgets/withdrawal_receipt_view.dart';

/// Yêu cầu rút tiền: kế toán chuyển khoản rồi nhập biên lai để duyệt (SRS 5.2, 8.1).
class WithdrawalsScreen extends ConsumerWidget {
  const WithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final list = ref.watch(adminWithdrawalsProvider);
    final busy = ref.watch(adminActionsProvider).isLoading;

    Future<void> markPaid(Withdrawal w) async {
      final receipt = await showModalBottomSheet<WithdrawalReceipt>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        builder: (sheet) => _ReceiptForm(withdrawal: w),
      );
      if (receipt == null || !context.mounted) return;
      await ref.read(adminActionsProvider.notifier).run(
        (r) => r.completeWithdrawal(w.id, receipt),
        [DataArea.wallet, DataArea.notifications],
      );
      if (!context.mounted) return;
      final error = ref.read(adminActionsProvider).error;
      if (error != null) showErrorSnack(context, error);
    }

    return AppPage(
      title: l10n.navWithdrawals,
      showBack: false,
      onRefresh: () => ref.refresh(adminWithdrawalsProvider.future),
      children: [
        AsyncValueView(
          value: list,
          onRetry: () => ref.invalidate(adminWithdrawalsProvider),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: l10n.nothingToDo,
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: InfoPanel(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      children: [
                        for (final (i, w) in items.indexed) ...[
                          if (i > 0)
                            Divider(height: 1, indent: 16, color: c.separator),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    PriceText(w.amount),
                                    const Spacer(),
                                    if (w.status == WithdrawalStatus.pending)
                                      FilledButton(
                                        onPressed: busy
                                            ? null
                                            : () => markPaid(w),
                                        child: Text(l10n.markPaid),
                                      )
                                    else
                                      StatusPill(
                                        w.status.label(l10n),
                                        tone: w.status.tone,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  w.userName ?? '',
                                  style: context.textStyles.titleSmall,
                                ),
                                Text(
                                  formatDateTime(w.createdAt),
                                  style: context.textStyles.bodySmall,
                                ),
                                if (w.bankName != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      l10n.admWdPayTo(
                                        w.bankName!,
                                        w.bankAccountNumber ?? '',
                                        w.bankAccountName ?? '',
                                      ),
                                      style: context.textStyles.bodyMedium,
                                    ),
                                  ),
                                if (w.note != null)
                                  Text(
                                    l10n.admWdNote(w.note!),
                                    style: context.textStyles.bodySmall,
                                  ),
                                if (w.approvedBy != null &&
                                    w.approvedAt != null)
                                  Text(
                                    l10n.admApprovedBy(
                                      w.approvedBy!,
                                      formatDateTime(w.approvedAt!),
                                    ),
                                    style: context.textStyles.bodySmall,
                                  ),
                                if (w.receipt != null)
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 36),
                                      alignment: Alignment.centerLeft,
                                    ),
                                    onPressed: () =>
                                        showReceiptSheet(context, w.receipt!),
                                    child: Text(l10n.admReceiptSeeLink),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Form biên lai khi duyệt: người chuyển, thời điểm, số tiền (phải đúng số yêu cầu), ảnh chứng từ (SRS 8.1).
class _ReceiptForm extends StatefulWidget {
  const _ReceiptForm({required this.withdrawal});

  final Withdrawal withdrawal;

  @override
  State<_ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<_ReceiptForm> {
  final _sender = TextEditingController();
  late final _amount = TextEditingController(
    text: '${widget.withdrawal.amount}',
  );
  var _time = DateTime.now();
  var _proof = const <String>[];
  var _submitted = false;

  @override
  void dispose() {
    _sender.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _time,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final at = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
    );
    if (at == null) return;
    setState(() {
      _time = DateTime(date.year, date.month, date.day, at.hour, at.minute);
    });
  }

  void _submit() {
    setState(() => _submitted = true);
    final amount = int.tryParse(_amount.text) ?? 0;
    if (_sender.text.trim().isEmpty ||
        _proof.isEmpty ||
        amount != widget.withdrawal.amount) {
      return;
    }
    Navigator.pop(
      context,
      WithdrawalReceipt(
        senderName: _sender.text.trim(),
        transferredAt: _time,
        amount: amount,
        proofImageUrl: _proof.first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
    final amount = int.tryParse(_amount.text) ?? 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.admReceiptTitle, style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.withdrawal.userName ?? ''} · ${formatVnd(widget.withdrawal.amount)}',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _sender,
              textCapitalization: TextCapitalization.characters,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: l10n.admReceiptSender,
                hintText: Rules.bankHolder.hint(l10n),
                counterText: '',
                errorText: _submitted && _sender.text.trim().isEmpty
                    ? l10n.admReceiptSenderRequired
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text('${l10n.admReceiptTime}: ${formatDateTime(_time)}'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: Rules.amount.formatters,
              maxLength: Rules.amount.maxLength,
              decoration: InputDecoration(
                labelText: l10n.admReceiptAmount,
                hintText: Rules.amount.hint(l10n),
                counterText: '',
                errorText: _submitted && amount != widget.withdrawal.amount
                    ? l10n.errReceiptMismatch
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.admReceiptProof, style: text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            PhotoPickerField(
              folder: 'withdrawal-receipts',
              max: 1,
              onChanged: (urls) => setState(() => _proof = urls),
            ),
            if (_submitted && _proof.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  l10n.admReceiptProofRequired,
                  style: text.bodySmall?.copyWith(color: context.colors.error),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _submit,
              child: Text(l10n.admReceiptConfirm),
            ),
          ],
        ),
      ),
    );
  }
}
