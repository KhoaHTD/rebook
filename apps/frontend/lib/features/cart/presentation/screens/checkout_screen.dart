import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/external_link.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/features/cart/presentation/providers/cart_providers.dart';
import 'package:book_marketplace/features/cart/presentation/widgets/cart_widgets.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/money_summary.dart';
import 'package:book_marketplace/shared/widgets/ui.dart';

/// Xác nhận đặt hàng: chọn địa chỉ (đổi phí ship), chọn COD / ví / VNPay, đặt hàng.
/// Hệ thống tách mỗi shop một đơn; một lần thanh toán trả cho nhiều đơn (SRS 4.2).
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  var _method = PaymentMethod.cod;

  Future<void> _place(String addressId) async {
    final result = await ref
        .read(checkoutControllerProvider.notifier)
        .placeOrder(addressId: addressId, method: _method);
    if (!mounted) return;
    final error = ref.read(checkoutControllerProvider).error;
    if (error != null || result == null) {
      showErrorSnack(context, error ?? Exception());
      return;
    }
    final payment = result.payment;
    if (payment != null && _method == PaymentMethod.vnpay) {
      if (isMockUrl(payment.paymentUrl)) {
        context.go(Routes.paymentResult(payment.id));
      } else {
        await openExternal(payment.paymentUrl!);
      }
      return;
    }
    showInfoSnack(context, context.l10n.ordersCreated(result.orders.length));
    context.go(Routes.orders);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = ref.watch(cartControllerProvider);
    final addresses = ref.watch(checkoutAddressesProvider);
    final wallet = ref.watch(checkoutWalletProvider).value;
    final selectedId = ref.watch(selectedAddressProvider);
    final busy = ref.watch(checkoutControllerProvider).isLoading;
    final compact = context.windowSize.isCompact;

    final addressList = addresses.value ?? const <Address>[];
    final address =
        addressList.where((a) => a.id == selectedId).firstOrNull ??
        addressList.where((a) => a.isDefault).firstOrNull ??
        addressList.firstOrNull;
    if (address != null && selectedId == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(selectedAddressProvider.notifier).select(address.id),
      );
    }

    final total = cart.value?.total ?? 0;
    final walletEnough = wallet != null && wallet.available >= total;

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.deliveryAddress, style: context.textStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        AsyncValueView(
          value: addresses,
          onRetry: () => ref.invalidate(checkoutAddressesProvider),
          data: (list) => list.isEmpty
              ? InfoPanel(
                  child: Row(
                    children: [
                      Expanded(child: Text(l10n.noAddress)),
                      TextButton(
                        onPressed: () => context.push(Routes.addresses),
                        child: Text(l10n.addAddress),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    for (final a in list)
                      SelectTile(
                        selected: a.id == address?.id,
                        title: '${a.receiver} · ${a.phone}',
                        subtitle: a.oneLine,
                        onTap: () => ref
                            .read(selectedAddressProvider.notifier)
                            .select(a.id),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push(Routes.addresses),
                        child: Text(l10n.addAddress),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.paymentMethod, style: context.textStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SelectTile(
          selected: _method == PaymentMethod.cod,
          leading: const Icon(Icons.payments_outlined),
          title: l10n.payCod,
          subtitle: l10n.payCodHint,
          onTap: () => setState(() => _method = PaymentMethod.cod),
        ),
        SelectTile(
          selected: _method == PaymentMethod.wallet,
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: l10n.payWallet,
          subtitle: walletEnough
              ? l10n.payWalletHint(formatVnd(wallet.available))
              : '${l10n.insufficientWallet} · ${l10n.payWalletHint(formatVnd(wallet?.available ?? 0))}',
          onTap: walletEnough
              ? () => setState(() => _method = PaymentMethod.wallet)
              : null,
        ),
        SelectTile(
          selected: _method == PaymentMethod.vnpay,
          leading: const Icon(Icons.qr_code_2_rounded),
          title: l10n.payVnpay,
          subtitle: l10n.payVnpayHint,
          onTap: () => setState(() => _method = PaymentMethod.vnpay),
        ),
        const SizedBox(height: AppSpacing.lg),
        AsyncValueView(
          value: cart,
          onRetry: () => ref.invalidate(cartControllerProvider),
          data: (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final g in c.groups) ...[
                CartGroupView(group: g),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ],
    );

    final summary = SummaryPanel(
      subtotal: cart.value?.subtotal ?? 0,
      shipping: cart.value?.shippingTotal ?? 0,
      total: total,
      action: FilledButton(
        onPressed:
            address == null || busy || (cart.value?.groups.isEmpty ?? true)
            ? null
            : () => _place(address.id),
        child: busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.placeOrder),
      ),
    );

    return AppPage(
      title: l10n.checkoutTitle,
      showBack: true,
      children: [
        if (compact) ...[
          form,
          summary,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: form),
              const SizedBox(width: AppSpacing.xl),
              SizedBox(width: 340, child: summary),
            ],
          ),
      ],
    );
  }
}
