import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/auction/presentation/providers/auction_providers.dart';
import 'package:book_marketplace/shared/domain/rules.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Đăng ký tham gia phiên: đọc quy chế, chọn mức cọc (hạn mức = cọc × 10), khóa cọc trong ví,
/// nhận số bài ẩn danh (SRS 6.4, 8.3).
class RegisterSessionScreen extends ConsumerStatefulWidget {
  const RegisterSessionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<RegisterSessionScreen> createState() =>
      _RegisterSessionScreenState();
}

class _RegisterSessionScreenState extends ConsumerState<RegisterSessionScreen> {
  static const _fees = FeeConfig();
  static const _multiples = [1, 2, 5, 10];
  var _multiple = 1;
  var _agreed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = ref.watch(sessionCatalogueProvider(widget.sessionId));
    final wallet = ref.watch(auctionWalletProvider).value;
    final busy = ref.watch(auctionActionsProvider).isLoading;

    return AppPage(
      title: l10n.registerToBid,
      showBack: true,
      children: [
        AsyncValueView(
          value: data,
          onRetry: () =>
              ref.invalidate(sessionCatalogueProvider(widget.sessionId)),
          data: (d) {
            final session = d.$1;
            final deposit = session.depositAmount * _multiple;
            final enough = (wallet?.available ?? 0) >= deposit;
            final rules = [
              l10n.ruleDeposit(
                formatVnd(session.depositAmount),
                _fees.depositLimitMultiplier,
              ),
              l10n.ruleLotTime(session.lotDurationSec, session.softCloseSec),
              l10n.ruleIncrement,
              l10n.rulePremium(_fees.buyerPremiumPercent.round(), 48),
              l10n.ruleRefund,
            ];
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(session.title, style: context.textStyles.headlineSmall),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.sessionRules,
                    style: context.textStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final r in rules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: CircleAvatar(
                              radius: 2.5,
                              backgroundColor: context.colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              r,
                              style: context.textStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.depositAmount,
                    style: context.textStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final m in _multiples)
                    SelectTile(
                      selected: _multiple == m,
                      title: l10n.depositOption(
                        formatVnd(session.depositAmount * m),
                        formatVnd(_fees.bidLimit(session.depositAmount * m)),
                      ),
                      onTap: () => setState(() => _multiple = m),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.payWalletHint(formatVnd(wallet?.available ?? 0)),
                    style: context.textStyles.bodySmall,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    title: Text(l10n.sessionRules),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!enough)
                    OutlinedButton(
                      onPressed: () => context.go(Routes.wallet),
                      child: Text(l10n.topUpFirst),
                    )
                  else
                    FilledButton(
                      onPressed: !_agreed || busy
                          ? null
                          : () async {
                              final reg = await ref
                                  .read(auctionActionsProvider.notifier)
                                  .register(session.id, deposit);
                              if (!context.mounted) return;
                              if (reg == null) {
                                return showErrorSnack(
                                  context,
                                  ref.read(auctionActionsProvider).error ??
                                      Exception(),
                                );
                              }
                              showInfoSnack(
                                context,
                                l10n.registerSuccess(reg.paddleNumber),
                              );
                              context.go(Routes.session(session.id));
                            },
                      child: Text(l10n.confirmRegister),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
