import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/external_link.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/core/utils/vietnamese.dart';
import 'package:book_marketplace/shared/data/vietnam_banks.dart';
import 'package:book_marketplace/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';
import 'package:book_marketplace/shared/widgets/withdrawal_receipt_view.dart';

/// Ví ReBook: số dư dùng được / đang khóa, nạp tiền VNPay, rút tiền (người bán), sổ giao dịch (SRS 8.1).
/// Khu mua sách chỉ hiện giao dịch mua bán; khu đấu giá ([auction]) chỉ hiện giao dịch cọc.
class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key, this.auction = false});

  final bool auction;

  static const _depositTypes = {
    WalletTxnType.depositHold,
    WalletTxnType.depositRelease,
    WalletTxnType.depositForfeit,
  };

  Future<int?> _askAmount(
    BuildContext context,
    String title, {
    String? hint,
    int? max,
  }) async {
    final l10n = context.l10n;
    final ctrl = TextEditingController();
    String? error;
    return showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(c).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: c.textStyles.titleLarge),
              if (hint != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(hint, style: c.textStyles.bodySmall),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  helperText: l10n.amountMin(
                    formatVnd(WalletController.minAmount),
                  ),
                  errorText: error,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () {
                  final v = int.tryParse(ctrl.text) ?? 0;
                  if (v < WalletController.minAmount) {
                    return setState(
                      () => error = l10n.amountMin(
                        formatVnd(WalletController.minAmount),
                      ),
                    );
                  }
                  if (max != null && v > max) {
                    return setState(() => error = l10n.amountTooHigh);
                  }
                  Navigator.pop(c, v);
                },
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final wallet = ref.watch(myWalletProvider);
    final txns = ref
        .watch(walletTransactionsProvider)
        .whenData(
          (all) => all
              .where((t) => _depositTypes.contains(t.type) == auction)
              .toList(),
        );
    final withdrawals =
        ref.watch(myWithdrawalsProvider).value ?? const <Withdrawal>[];
    final isSeller =
        ref.watch(sessionControllerProvider).user?.hasShop ?? false;
    final busy = ref.watch(walletControllerProvider).isLoading;

    Future<void> topUp() async {
      final amount = await _askAmount(context, l10n.topUp);
      if (amount == null) return;
      final p = await ref.read(walletControllerProvider.notifier).topUp(amount);
      if (!context.mounted) return;
      final err = ref.read(walletControllerProvider).error;
      if (err != null || p == null) {
        return showErrorSnack(context, err ?? Exception());
      }
      if (isMockUrl(p.paymentUrl)) {
        context.go(Routes.paymentResult(p.id));
      } else {
        await openExternal(p.paymentUrl!);
      }
    }

    Future<void> withdraw(int available) async {
      final form = await showModalBottomSheet<_WithdrawForm>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        builder: (_) => _WithdrawSheet(available: available),
      );
      if (form == null || !context.mounted) return;
      final ok = await ref
          .read(walletControllerProvider.notifier)
          .withdraw(
            form.amount,
            bankName: form.bank,
            accountNumber: form.number,
            accountName: form.name,
            note: form.note,
          );
      if (!context.mounted) return;
      ok
          ? showInfoSnack(context, l10n.withdrawSent)
          : showErrorSnack(context, ref.read(walletControllerProvider).error!);
    }

    return AppPage(
      title: auction ? l10n.auctionWalletTitle : l10n.wallet,
      onRefresh: () => ref.refresh(myWalletProvider.future),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AsyncValueView(
                value: wallet,
                onRetry: () => ref.invalidate(myWalletProvider),
                data: (w) => InfoPanel(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.available, style: context.textStyles.bodySmall),
                      PriceText(
                        w.available,
                        style: context.textStyles.headlineMedium?.copyWith(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${l10n.held}: ${formatVnd(w.held)}',
                        style: context.textStyles.bodyMedium,
                      ),
                      Text(l10n.heldHint, style: context.textStyles.bodySmall),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          FilledButton.icon(
                            onPressed: busy ? null : topUp,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(l10n.topUp),
                          ),
                          if (isSeller && !auction)
                            OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => withdraw(w.available),
                              child: Text(l10n.withdraw),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (withdrawals.isNotEmpty && !auction) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.withdrawals, style: context.textStyles.titleMedium),
                for (final w in withdrawals)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(formatVnd(w.amount)),
                    subtitle: Text(
                      w.receipt == null
                          ? formatDateTime(w.createdAt)
                          : '${formatDateTime(w.createdAt)} · ${l10n.receiptTitle}',
                    ),
                    onTap: w.receipt == null
                        ? null
                        : () => showReceiptSheet(context, w.receipt!),
                    trailing: StatusPill(
                      w.status.label(l10n),
                      tone: w.status.tone,
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                auction ? l10n.depositHistory : l10n.transactions,
                style: context.textStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              AsyncValueView(
                value: txns,
                onRetry: () => ref.invalidate(walletTransactionsProvider),
                data: (list) => list.isEmpty
                    ? Text(
                        l10n.noTransactions,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: c.secondaryText,
                        ),
                      )
                    : Column(
                        children: [
                          for (final t in list)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(t.type.label(l10n)),
                              subtitle: Text(
                                '${formatDateTime(t.createdAt)}${t.note == null ? '' : ' · ${t.note}'}',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${t.amount > 0 ? '+' : ''}${formatVnd(t.amount)}',
                                    style: context.textStyles.titleSmall
                                        ?.copyWith(
                                          color: t.amount >= 0
                                              ? c.success
                                              : context.colors.onSurface,
                                        ),
                                  ),
                                  Text(
                                    l10n.balanceAfter(
                                      formatVnd(t.balanceAfter),
                                    ),
                                    style: context.textStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kết quả form rút tiền.
class _WithdrawForm {
  const _WithdrawForm(
    this.amount,
    this.bank,
    this.number,
    this.name,
    this.note,
  );

  final int amount;
  final String bank;
  final String number;
  final String name;
  final String? note;
}

/// Tạo yêu cầu rút tiền: số tiền, ngân hàng, số tài khoản, tên chủ tài khoản (in hoa, không dấu), ghi chú (SRS 8.1).
class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.available});

  final int available;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amount = TextEditingController();
  final _number = TextEditingController();
  final _name = TextEditingController();
  final _note = TextEditingController();
  String? _bank;
  var _submitted = false;

  @override
  void dispose() {
    _amount.dispose();
    _number.dispose();
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _amountError(AppLocalizations l10n) {
    final v = int.tryParse(_amount.text) ?? 0;
    if (v < WalletController.minAmount) {
      return l10n.amountMin(formatVnd(WalletController.minAmount));
    }
    if (v > widget.available) return l10n.amountTooHigh;
    return null;
  }

  void _submit(AppLocalizations l10n) {
    setState(() => _submitted = true);
    final numberOk = RegExp(r'^\d{6,19}$').hasMatch(_number.text);
    if (_amountError(l10n) != null ||
        _bank == null ||
        !numberOk ||
        _name.text.trim().isEmpty) {
      return;
    }
    final note = _note.text.trim();
    Navigator.pop(
      context,
      _WithdrawForm(
        int.parse(_amount.text),
        _bank!,
        _number.text,
        _name.text.trim(),
        note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = context.textStyles;
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
            Text(l10n.withdraw, style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.wdDeductHint, style: text.bodySmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.amount,
                helperText: l10n.amountMin(
                  formatVnd(WalletController.minAmount),
                ),
                errorText: _submitted ? _amountError(l10n) : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _bank,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.wdBank,
                hintText: l10n.wdBankHint,
                errorText: _submitted && _bank == null ? l10n.wdNeedBank : null,
              ),
              items: [
                for (final b in vietnamBanks)
                  DropdownMenuItem(value: b, child: Text(b)),
              ],
              onChanged: (v) => setState(() => _bank = v),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _number,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
              ],
              decoration: InputDecoration(
                labelText: l10n.wdAccountNumber,
                errorText:
                    _submitted && !RegExp(r'^\d{6,19}$').hasMatch(_number.text)
                    ? l10n.wdNeedNumber
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.wdAccountName,
                errorText: _submitted && _name.text.trim().isEmpty
                    ? l10n.wdNeedName
                    : null,
              ),
              // Gõ có dấu / chữ thường thì tự đổi thành IN HOA không dấu.
              onChanged: (v) {
                final fixed = bankAccountName(v);
                if (fixed != v) {
                  _name.value = TextEditingValue(
                    text: fixed,
                    selection: TextSelection.collapsed(offset: fixed.length),
                  );
                }
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _note,
              maxLength: 120,
              decoration: InputDecoration(labelText: l10n.wdNote),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => _submit(l10n),
              child: Text(l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }
}
