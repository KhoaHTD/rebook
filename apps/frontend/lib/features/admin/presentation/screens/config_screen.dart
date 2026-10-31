import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/admin/presentation/providers/admin_providers.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/rules.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Cấu hình phí, hạn thanh toán, hạn mức cọc, bước giá (SRS 8.2, 5.3).
class ConfigScreen extends ConsumerWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(systemConfigProvider);
    return AppPage(
      title: context.l10n.navConfig,
      showBack: false,
      children: [
        AsyncValueView(
          value: config,
          onRetry: () => ref.invalidate(systemConfigProvider),
          data: (c) => Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _ConfigForm(initial: c),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfigForm extends ConsumerStatefulWidget {
  const _ConfigForm({required this.initial});

  final SystemConfig initial;

  @override
  ConsumerState<_ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends ConsumerState<_ConfigForm> {
  late final _fields = <String, TextEditingController>{
    'fixed': TextEditingController(
      text: _n(widget.initial.fixedPriceFeePercent),
    ),
    'premium': TextEditingController(
      text: _n(widget.initial.buyerPremiumPercent),
    ),
    'commission': TextEditingController(
      text: _n(widget.initial.sellerCommissionPercent),
    ),
    'storage': TextEditingController(
      text: '${widget.initial.storageFeePerDay}',
    ),
    'free': TextEditingController(text: '${widget.initial.storageFreeDays}'),
    'payMin': TextEditingController(
      text: '${widget.initial.orderPaymentTimeoutMin}',
    ),
    'payHours': TextEditingController(
      text: '${widget.initial.auctionPaymentTimeoutHours}',
    ),
    'multiplier': TextEditingController(
      text: '${widget.initial.depositLimitMultiplier}',
    ),
    'ban': TextEditingController(text: '${widget.initial.auctionBanDays}'),
    'returnDays': TextEditingController(
      text: '${widget.initial.returnResponseDays}',
    ),
  };
  late final _tiers = [
    for (final t in widget.initial.bidTiers)
      (
        TextEditingController(text: '${t.fromPrice}'),
        TextEditingController(text: '${t.increment}'),
      ),
  ];

  static String _n(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    for (final (a, b) in _tiers) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    double d(String k) => double.tryParse(_fields[k]!.text) ?? 0;
    int i(String k) => int.tryParse(_fields[k]!.text) ?? 0;
    final config = SystemConfig(
      fixedPriceFeePercent: d('fixed'),
      buyerPremiumPercent: d('premium'),
      sellerCommissionPercent: d('commission'),
      storageFeePerDay: i('storage'),
      storageFreeDays: i('free'),
      orderPaymentTimeoutMin: i('payMin'),
      auctionPaymentTimeoutHours: i('payHours'),
      depositLimitMultiplier: i('multiplier'),
      auctionBanDays: i('ban'),
      returnResponseDays: i('returnDays'),
      bidTiers: [
        for (final (a, b) in _tiers)
          BidTier(int.tryParse(a.text) ?? 0, int.tryParse(b.text) ?? 0),
      ]..sort((x, y) => x.fromPrice.compareTo(y.fromPrice)),
    );
    final r = await ref
        .read(adminActionsProvider.notifier)
        .run((repo) => repo.updateConfig(config), const []);
    if (!mounted) return;
    if (r == null) {
      showErrorSnack(context, ref.read(adminActionsProvider).error!);
    } else {
      ref.invalidate(systemConfigProvider);
      showInfoSnack(context, context.l10n.saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = ref.watch(adminActionsProvider).isLoading;
    Widget field(String key, String label) => SizedBox(
      width: 220,
      child: TextField(
        controller: _fields[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      ),
    );
    Widget number(TextEditingController c, String label) => Expanded(
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoPanel(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              field('fixed', l10n.fixedPriceFee),
              field('premium', l10n.buyerPremiumPct),
              field('commission', l10n.sellerCommissionPct),
              field('storage', l10n.storageFee),
              field('free', l10n.storageFreeDays),
              field('payMin', l10n.paymentTimeoutMin),
              field('payHours', l10n.auctionPaymentHours),
              field('multiplier', l10n.depositMultiplier),
              field('ban', l10n.banDays),
              field('returnDays', l10n.admReturnResponseDays),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        InfoPanel(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.bidTiers, style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.md),
              for (final (a, b) in _tiers)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      number(a, l10n.fromPrice),
                      const SizedBox(width: AppSpacing.sm),
                      number(b, l10n.increment),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: busy ? null : _save,
            child: Text(l10n.save),
          ),
        ),
      ],
    );
  }
}
