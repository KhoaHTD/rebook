import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/external_link.dart';
import 'package:book_marketplace/features/cart/presentation/providers/cart_providers.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Kết quả một lần thanh toán VNPay (đơn hàng, nạp ví, hóa đơn lô đấu giá).
/// Chế độ mock: hiện cổng VNPay giả lập để chọn thành công / thất bại.
class PaymentResultScreen extends ConsumerWidget {
  const PaymentResultScreen({super.key, required this.paymentId});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final payment = ref.watch(paymentProvider(paymentId));
    return AppPage(
      title: l10n.paymentTitle,
      onRefresh: () => ref.refresh(paymentProvider(paymentId).future),
      children: [
        AsyncValueView(
          value: payment,
          onRetry: () => ref.invalidate(paymentProvider(paymentId)),
          data: (p) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _Body(payment: p),
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.appColors;
    final busy = ref.watch(gatewayControllerProvider).isLoading;
    final (icon, color, title) = switch (payment.status) {
      PaymentStatus.pending => (
        Icons.hourglass_top_rounded,
        c.warning,
        l10n.paymentPending,
      ),
      PaymentStatus.success => (
        Icons.check_circle_rounded,
        c.success,
        l10n.paymentSuccess,
      ),
      PaymentStatus.failed => (
        Icons.cancel_rounded,
        c.live,
        l10n.paymentFailed,
      ),
      PaymentStatus.expired => (
        Icons.timer_off_rounded,
        c.secondaryText,
        l10n.paymentExpired,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(icon, size: 64, color: color),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.textStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: PriceText(
            payment.amount,
            style: context.textStyles.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (payment.status == PaymentStatus.pending &&
            isMockUrl(payment.paymentUrl))
          InfoPanel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.mockGatewayTitle,
                  style: context.textStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.mockGatewayHint, style: context.textStyles.bodySmall),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => ref
                            .read(gatewayControllerProvider.notifier)
                            .pay(payment.id, success: true),
                  child: Text(l10n.paymentSuccess),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => ref
                            .read(gatewayControllerProvider.notifier)
                            .pay(payment.id, success: false),
                  child: Text(l10n.paymentFailed),
                ),
              ],
            ),
          )
        else if (payment.status == PaymentStatus.pending &&
            payment.paymentUrl != null)
          FilledButton(
            onPressed: () => openExternal(payment.paymentUrl!),
            child: Text(l10n.payNow),
          )
        else ...[
          FilledButton(
            onPressed: () => context.go(Routes.orders),
            child: Text(l10n.viewOrders),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => context.go(Routes.home),
            child: Text(l10n.continueShopping),
          ),
        ],
      ],
    );
  }
}
