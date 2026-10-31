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
import 'package:book_marketplace/features/cart/presentation/widgets/flat_commerce_widgets.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/data/vietnam_geo.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/async_value_view.dart';
import 'package:book_marketplace/shared/widgets/error_view.dart';
import 'package:book_marketplace/shared/widgets/money_summary.dart';
import 'package:book_marketplace/shared/widgets/vietnam_map.dart';
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
        .placeOrder(
          addressId: addressId,
          method: _method,
          itemIds: ref.read(selectedCartItemIdsProvider),
        );
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

  /// Chọn địa chỉ khác (hoặc thêm địa chỉ) trong một tờ.
  Future<void> _pickAddress(List<Address> list, String? currentId) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.deliveryAddress, style: sheet.textStyles.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final a in list)
                SelectTile(
                  selected: a.id == currentId,
                  title: '${a.receiver} · ${a.phone}',
                  subtitle: a.oneLine,
                  onTap: () {
                    ref.read(selectedAddressProvider.notifier).select(a.id);
                    Navigator.pop(sheet);
                  },
                ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheet);
                  context.push(Routes.addresses);
                },
                child: Text(l10n.addAddress),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tờ trượt lên: sơ đồ Việt Nam (có Hoàng Sa, Trường Sa) ghim ở tỉnh / thành của địa chỉ, kèm địa chỉ đầy đủ.
  Future<void> _showMap(Address address, VoidCallback onChange) {
    final l10n = context.l10n;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheet) {
        final text = sheet.textStyles;
        final c = sheet.appColors;
        final pin = address.hasPin
            ? (address.latitude!, address.longitude!)
            : null;
        final located =
            pin != null || VietnamGeo.province(address.province) != null;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.addressMapTitle,
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheet).height * 0.5,
                  ),
                  child: Center(
                    child: VietnamMap(province: address.province, point: pin),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${address.receiver} · ${address.phone}',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  address.oneLine,
                  style: text.bodyMedium?.copyWith(color: c.secondaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  pin != null
                      ? l10n.addrPinned
                      : located
                      ? l10n.mapApprox
                      : l10n.mapNoPin,
                  style: text.bodySmall?.copyWith(color: c.tertiaryText),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    onChange();
                  },
                  child: Text(l10n.changeAddress),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Điện thoại: thanh toán phẳng — thẻ địa chỉ, ba ô phương thức, thẻ đen giải thích, tóm tắt đơn,
  /// tổng thanh toán và nút đen "Xác nhận đặt hàng" ghim ở đáy.
  Widget _compact(
    BuildContext context, {
    required Cart? cartValue,
    required List<Address> addressList,
    required Address? address,
    required Wallet? wallet,
    required bool walletEnough,
    required bool busy,
  }) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final total = cartValue?.total ?? 0;
    final (cardTitle, cardHint) = switch (_method) {
      PaymentMethod.cod => (l10n.payCod, l10n.payCodHint),
      PaymentMethod.wallet => (
        l10n.payWallet,
        l10n.payWalletHint(formatVnd(wallet?.available ?? 0)),
      ),
      PaymentMethod.vnpay => (l10n.payVnpay, l10n.payVnpayHint),
    };
    Widget heading(String t, {double top = 22}) => Padding(
      padding: EdgeInsets.only(top: top, bottom: 10),
      child: Text(
        t,
        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );

    return FlatCommercePage(
      title: l10n.checkoutTitle,
      bottom: FlatBlackButton(
        label: l10n.confirmOrder,
        busy: busy,
        onPressed: address == null || (cartValue?.groups.isEmpty ?? true)
            ? null
            : () => _place(address.id),
      ),
      children: [
        heading(l10n.checkoutShippingTo, top: 0),
        if (address == null)
          FlatCard(
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
        else
          FlatAddressCard(
            address: address,
            onChange: () => _pickAddress(addressList, address.id),
            onOpenMap: () =>
                _showMap(address, () => _pickAddress(addressList, address.id)),
          ),
        heading(l10n.paymentMethod),
        Row(
          children: [
            FlatPayTile(
              icon: Icons.payments_rounded,
              color: PayPalette.cod,
              label: l10n.payShortCod,
              selected: _method == PaymentMethod.cod,
              onTap: () => setState(() => _method = PaymentMethod.cod),
            ),
            const SizedBox(width: 12),
            FlatPayTile(
              icon: Icons.account_balance_wallet_rounded,
              color: PayPalette.wallet,
              label: l10n.payShortWallet,
              selected: _method == PaymentMethod.wallet,
              onTap: walletEnough
                  ? () => setState(() => _method = PaymentMethod.wallet)
                  : null,
            ),
            const SizedBox(width: 12),
            FlatPayTile(
              icon: Icons.qr_code_2_rounded,
              color: PayPalette.vnpay,
              label: l10n.payShortVnpay,
              selected: _method == PaymentMethod.vnpay,
              onTap: () => setState(() => _method = PaymentMethod.vnpay),
            ),
          ],
        ),
        if (!walletEnough && wallet != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${l10n.insufficientWallet} · ${l10n.payWalletHint(formatVnd(wallet.available))}',
              style: text.bodySmall?.copyWith(color: c.secondaryText),
            ),
          ),
        const SizedBox(height: 16),
        FlatPayCard(
          method: _method,
          title: cardTitle,
          hint: cardHint,
          balance: _method == PaymentMethod.wallet && wallet != null
              ? formatVnd(wallet.available)
              : null,
        ),
        heading(l10n.orderSummary),
        FlatCard(
          child: Column(
            children: [
              if (cartValue != null)
                for (final g in cartValue.groups) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${g.shop.name} · ${l10n.items(g.items.fold<int>(0, (a, i) => a + i.quantity))}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium,
                        ),
                      ),
                      Text(
                        formatVnd(g.subtotal + g.shippingFee),
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              Divider(color: c.separator),
              FlatMoneyRow(l10n.subtotal, cartValue?.subtotal ?? 0),
              FlatMoneyRow(l10n.shippingFee, cartValue?.shippingTotal ?? 0),
              Divider(color: c.separator),
              FlatMoneyRow(l10n.totalPayment, total, strong: true),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = ref.watch(selectedCartProvider);
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

    if (compact) {
      return _compact(
        context,
        cartValue: cart.value,
        addressList: addressList,
        address: address,
        wallet: wallet,
        walletEnough: walletEnough,
        busy: busy,
      );
    }

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
          onRetry: () => ref.invalidate(selectedCartProvider),
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
