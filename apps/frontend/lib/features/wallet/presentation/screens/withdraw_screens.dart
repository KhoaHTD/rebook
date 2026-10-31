import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/core/utils/vietnamese.dart';
import 'package:book_marketplace/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:book_marketplace/features/wallet/presentation/providers/withdraw_draft.dart';
import 'package:book_marketplace/shared/data/vietnam_banks.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/widgets/bank_badge.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/status_labels.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Bước 1: chọn ngân hàng nhận tiền (có ô tìm kiếm).
class WithdrawBankScreen extends ConsumerStatefulWidget {
  const WithdrawBankScreen({super.key});

  @override
  ConsumerState<WithdrawBankScreen> createState() => _WithdrawBankScreenState();
}

class _WithdrawBankScreenState extends ConsumerState<WithdrawBankScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final q = removeDiacritics(_search.text).toLowerCase().trim();
    final banks = [
      for (final b in vietnamBanks)
        if (q.isEmpty || removeDiacritics(b).toLowerCase().contains(q)) b,
    ];
    return AppPage(
      title: l10n.wdSelectBank,
      showBack: true,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: l10n.wdSearchBank,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final (i, b) in banks.indexed) ...[
                if (i > 0) Divider(height: 1, indent: 56, color: c.separator),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: BankBadge(b),
                  title: Text(b, style: context.textStyles.titleMedium),
                  onTap: () {
                    ref
                        .read(withdrawDraftControllerProvider.notifier)
                        .selectBank(b);
                    context.push(Routes.withdrawAccount);
                  },
                ),
              ],
              const SizedBox(height: 110),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bước 2: số tài khoản + tên chủ tài khoản, kèm danh sách tài khoản đã dùng của ngân hàng này.
class WithdrawAccountScreen extends ConsumerStatefulWidget {
  const WithdrawAccountScreen({super.key});

  @override
  ConsumerState<WithdrawAccountScreen> createState() =>
      _WithdrawAccountScreenState();
}

class _WithdrawAccountScreenState extends ConsumerState<WithdrawAccountScreen> {
  late final _number = TextEditingController(
    text: ref.read(withdrawDraftControllerProvider).accountNumber,
  );
  late final _name = TextEditingController(
    text: ref.read(withdrawDraftControllerProvider).accountName,
  );

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  bool get _valid =>
      RegExp(r'^\d{6,19}$').hasMatch(_number.text) &&
      _name.text.trim().isNotEmpty;

  void _save() => ref
      .read(withdrawDraftControllerProvider.notifier)
      .setAccount(_number.text, _name.text.trim());

  void _useRecent(BankAccount a) {
    _number.text = a.accountNumber;
    _name.text = a.accountName;
    ref
        .read(withdrawDraftControllerProvider.notifier)
        .setAccount(a.accountNumber, a.accountName, favorite: a.favorite);
    context.push(Routes.withdrawAmount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final bank = ref.watch(withdrawDraftControllerProvider).bank;
    if (bank == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.withdrawBank);
      });
      return const SizedBox.shrink();
    }
    final recents = [
      for (final a
          in ref.watch(bankAccountsProvider).value ?? const <BankAccount>[])
        if (a.bankName == bank) a,
    ];
    return AppPage(
      title: l10n.wdTransferTitle,
      showBack: true,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        BankBadge(bank),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: Text(bank, style: text.titleMedium)),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text('${l10n.wdChange} ›'),
                        ),
                      ],
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
                      ),
                      onChanged: (_) {
                        _save();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: l10n.wdAccountName,
                      ),
                      // Gõ có dấu / chữ thường thì tự đổi thành IN HOA không dấu.
                      onChanged: (v) {
                        final fixed = bankAccountName(v);
                        if (fixed != v) {
                          _name.value = TextEditingValue(
                            text: fixed,
                            selection: TextSelection.collapsed(
                              offset: fixed.length,
                            ),
                          );
                        }
                        _save();
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _valid
                          ? () {
                              _save();
                              context.push(Routes.withdrawAmount);
                            }
                          : null,
                      child: Text(l10n.wdContinue),
                    ),
                  ],
                ),
              ),
              if (recents.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                InfoPanel(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(l10n.wdRecent, style: text.titleSmall),
                      ),
                      for (final a in recents) ...[
                        Divider(height: 1, color: c.separator),
                        ListTile(
                          leading: BankBadge(a.bankName),
                          title: Text(a.accountName),
                          subtitle: Text('${a.bankName} ${a.accountNumber}'),
                          trailing: a.favorite
                              ? Icon(
                                  Icons.star_rounded,
                                  color: c.warning,
                                  semanticLabel: l10n.wdFavorite,
                                )
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () => _useRecent(a),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 110),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bước 3: số tiền (gợi ý nhanh + rút hết), nguồn tiền, ghi chú, tổng và nút Tiếp.
class WithdrawAmountScreen extends ConsumerStatefulWidget {
  const WithdrawAmountScreen({super.key});

  @override
  ConsumerState<WithdrawAmountScreen> createState() =>
      _WithdrawAmountScreenState();
}

class _WithdrawAmountScreenState extends ConsumerState<WithdrawAmountScreen> {
  static const _quick = [100000, 500000, 1000000];

  final _amount = TextEditingController();
  late final _note = TextEditingController();
  var _noteReady = false;
  var _submitted = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text) ?? 0;

  String? _error(AppLocalizations l10n, int available) {
    if (_value < WalletController.minAmount) {
      return l10n.amountMin(formatVnd(WalletController.minAmount));
    }
    if (_value > available) return l10n.amountTooHigh;
    return null;
  }

  void _setAmount(int v) {
    _amount.text = '$v';
    _amount.selection = TextSelection.collapsed(offset: _amount.text.length);
    ref.read(withdrawDraftControllerProvider.notifier).setAmount(v);
    setState(() {});
  }

  Future<void> _submit(int available) async {
    final l10n = context.l10n;
    setState(() => _submitted = true);
    if (_error(l10n, available) != null) return;
    final draft = ref.read(withdrawDraftControllerProvider);
    final ctl = ref.read(walletControllerProvider.notifier);
    final created = await ctl.withdraw(
      _value,
      bankName: draft.bank!,
      accountNumber: draft.accountNumber,
      accountName: draft.accountName,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!mounted) return;
    if (created == null) {
      return showErrorSnack(context, ref.read(walletControllerProvider).error!);
    }
    // Ngôi sao: backend đã lưu tài khoản khi tạo yêu cầu, giờ đồng bộ trạng thái yêu thích.
    final saved = await ref.refresh(bankAccountsProvider.future);
    for (final a in saved) {
      if (a.bankName == draft.bank &&
          a.accountNumber == draft.accountNumber &&
          a.favorite != draft.favorite) {
        await ctl.setBankFavorite(a.id, on: draft.favorite);
      }
    }
    if (!mounted) return;
    ref.read(withdrawDraftControllerProvider.notifier)
      ..setAmount(_value)
      ..setResult(created);
    context.go(Routes.withdrawDone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final draft = ref.watch(withdrawDraftControllerProvider);
    final wallet = ref.watch(myWalletProvider).value;
    final available = wallet?.available ?? 0;
    final busy = ref.watch(walletControllerProvider).isLoading;
    if (draft.bank == null || draft.accountNumber.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.withdrawBank);
      });
      return const SizedBox.shrink();
    }
    if (!_noteReady) {
      _noteReady = true;
      _note.text = draft.note ?? l10n.wdDefaultNote(draft.accountName);
    }
    final error = _submitted ? _error(l10n, available) : null;
    final ok = _error(l10n, available) == null;
    final quick = [
      for (final q in _quick)
        if (q <= available) q,
    ];

    return AppPage(
      title: l10n.withdraw,
      showBack: true,
      bottomBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.wdTotal, style: text.bodySmall),
                    Text(
                      formatVnd(_value),
                      style: text.headlineSmall?.copyWith(
                        color: c.live,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: busy || !ok ? null : () => _submit(available),
                child: Text(l10n.wdNext),
              ),
            ],
          ),
        ),
      ),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: BankPalette.colorOf(draft.bank!),
                      child: Text(
                        draft.accountName.characters.first,
                        style: text.titleMedium?.copyWith(
                          color: CoverPalette.onHero,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(draft.accountName, style: text.titleMedium),
                          Text(
                            '${draft.bank} ${draft.accountNumber}',
                            style: text.bodySmall?.copyWith(
                              color: c.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.wdFavorite,
                      icon: Icon(
                        draft.favorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: draft.favorite ? c.warning : c.secondaryText,
                      ),
                      onPressed: () => ref
                          .read(withdrawDraftControllerProvider.notifier)
                          .setFavorite(!draft.favorite),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InfoPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.wdAmountLabel, style: text.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: 'đ',
                        errorText: error,
                      ),
                      onChanged: (_) {
                        ref
                            .read(withdrawDraftControllerProvider.notifier)
                            .setAmount(_value);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final q in quick)
                          ActionChip(
                            label: Text(formatVnd(q)),
                            onPressed: () => _setAmount(q),
                          ),
                        if (available >= WalletController.minAmount)
                          ActionChip(
                            label: Text(l10n.wdWithdrawAll),
                            onPressed: () => _setAmount(available),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InfoPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: c.tint),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l10n.wdSource}: ${l10n.wdSourceWallet}',
                            style: text.titleSmall,
                          ),
                          Text(
                            l10n.wdAvailable(formatVnd(available)),
                            style: text.bodySmall?.copyWith(
                              color: c.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_rounded, color: c.tint),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InfoPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  controller: _note,
                  maxLength: 140,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    labelText: l10n.wdDescription,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.cancel_rounded),
                      onPressed: () => setState(_note.clear),
                    ),
                  ),
                  onChanged: (v) => ref
                      .read(withdrawDraftControllerProvider.notifier)
                      .setNote(v),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.wdDeductHint, style: text.bodySmall),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kết quả: đã gửi yêu cầu, chờ Admin duyệt.
class WithdrawDoneScreen extends ConsumerWidget {
  const WithdrawDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final w = ref.watch(withdrawDraftControllerProvider).result;
    if (w == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.wallet);
      });
      return const SizedBox.shrink();
    }
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: c.secondaryText),
            ),
          ),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
    return AppPage(
      title: l10n.withdraw,
      showBack: false,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.check_circle_rounded, size: 64, color: c.success),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.wdDoneTitle,
                textAlign: TextAlign.center,
                style: text.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.wdDoneHint,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: c.secondaryText),
              ),
              const SizedBox(height: AppSpacing.xl),
              InfoPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (w.bankName != null)
                          BankBadge(w.bankName!, size: 36),
                        const Spacer(),
                        StatusPill(w.status.label(l10n), tone: w.status.tone),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    row(l10n.wdBank, w.bankName ?? ''),
                    row(l10n.wdAccountNumber, w.bankAccountNumber ?? ''),
                    row(l10n.wdAccountHolder, w.bankAccountName ?? ''),
                    row(l10n.wdAmountLabel, formatVnd(w.amount)),
                    if (w.note != null) row(l10n.wdDescription, w.note!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () {
                  ref.read(withdrawDraftControllerProvider.notifier).reset();
                  context.go(Routes.wallet);
                },
                child: Text(l10n.wdBackToWallet),
              ),
              const SizedBox(height: 110),
            ],
          ),
        ),
      ],
    );
  }
}
