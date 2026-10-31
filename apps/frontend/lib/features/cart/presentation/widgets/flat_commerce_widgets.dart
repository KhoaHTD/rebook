import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/user.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';

/// Màu nền trang của giỏ hàng / thanh toán điện thoại: xám rất nhạt, để các thẻ trắng nổi lên.
Color flatPageColor(BuildContext context) =>
    Color.alphaBlend(context.appColors.fill, context.colors.surface);

/// Khung trang phẳng cho giỏ hàng / thanh toán (điện thoại): nền xám nhạt, thanh đầu có mũi tên quay lại
/// và tiêu đề giữa, nội dung cuộn, nút hành động đen ghim ở đáy.
class FlatCommercePage extends StatelessWidget {
  const FlatCommercePage({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.bottom,
    this.onBack,
  });

  final String title;
  final List<Widget> children;

  /// Nút bên phải thanh đầu (vd. túi hàng kèm số lượng).
  final Widget? trailing;
  final Widget? bottom;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: flatPageColor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    onPressed:
                        onBack ??
                        () => context.canPop()
                            ? context.pop()
                            : context.go(Routes.home),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: trailing == null
                        ? null
                        : Align(alignment: Alignment.center, child: trailing),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: children,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottom == null
          ? null
          : ColoredBox(
              color: flatPageColor(context),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: bottom,
                ),
              ),
            ),
    );
  }
}

/// Thẻ trắng bo lớn, không viền, không kính.
class FlatCard extends StatelessWidget {
  const FlatCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// Nút hành động đen đặc bản rộng (ghim ở đáy).
class FlatBlackButton extends StatelessWidget {
  const FlatBlackButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        backgroundColor: context.colors.onSurface,
        foregroundColor: context.colors.surface,
        shape: const StadiumBorder(),
        textStyle: context.textStyles.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.surface,
              ),
            )
          : Text(label),
    );
  }
}

/// Một dòng tiền: nhãn xám bên trái, số tiền đậm bên phải.
class FlatMoneyRow extends StatelessWidget {
  const FlatMoneyRow(this.label, this.amount, {super.key, this.strong = false});

  final String label;
  final int amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: (strong ? text.titleSmall : text.bodyMedium)?.copyWith(
                color: strong
                    ? context.colors.onSurface
                    : context.appColors.secondaryText,
                fontWeight: strong ? FontWeight.w800 : null,
              ),
            ),
          ),
          Text(
            formatVnd(amount),
            style: (strong ? text.titleLarge : text.titleSmall)?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhóm một shop trong giỏ: tên shop, các dòng sách, phí ship của shop.
class FlatCartGroup extends StatelessWidget {
  const FlatCartGroup({
    super.key,
    required this.group,
    this.onQuantity,
    this.excluded = const {},
    this.onToggleItem,
    this.onToggleShop,
  });

  final CartGroup group;

  /// Các món đang bỏ chọn; [onToggleItem] / [onToggleShop] null = không hiện ô chọn (bước xác nhận).
  final Set<String> excluded;
  final ValueChanged<CartItem>? onToggleItem;
  final ValueChanged<bool>? onToggleShop;

  /// null = chỉ xem.
  final void Function(CartItem item, int quantity)? onQuantity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    return FlatCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.go(Routes.shop(group.shop.id)),
            child: Row(
              children: [
                if (onToggleShop != null) ...[
                  _TickBox(
                    value: _shopState(group, excluded),
                    onChanged: () =>
                        onToggleShop!(_shopState(group, excluded) != true),
                  ),
                  const SizedBox(width: 6),
                ],
                Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: c.secondaryText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: c.tertiaryText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final item in group.items)
            _FlatItemRow(
              item: item,
              onQuantity: onQuantity,
              selected: onToggleItem == null
                  ? null
                  : !excluded.contains(item.id),
              onToggle: onToggleItem,
            ),
          Divider(height: 1, color: c.separator),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.shippingFee,
                    style: text.bodySmall?.copyWith(color: c.secondaryText),
                  ),
                ),
                Text(
                  formatVnd(group.shippingFee),
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// true = chọn hết, false = không chọn món nào, null = chọn một phần.
bool? _shopState(CartGroup g, Set<String> excluded) {
  final selected = g.items.where((i) => !excluded.contains(i.id)).length;
  if (selected == g.items.length) return true;
  return selected == 0 ? false : null;
}

/// Ô chọn nhỏ gọn cho giỏ hàng.
class _TickBox extends StatelessWidget {
  const _TickBox({required this.value, required this.onChanged});

  final bool? value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 28,
    child: Checkbox(
      value: value,
      tristate: true,
      shape: const CircleBorder(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onChanged: (_) => onChanged(),
    ),
  );
}

/// Dòng "Chọn tất cả" ở đầu giỏ.
class CartSelectAllBar extends StatelessWidget {
  const CartSelectAllBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onChanged,
  });

  final int selectedCount;
  final int totalCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = selectedCount == totalCount;
    return Row(
      children: [
        _TickBox(
          value: all ? true : (selectedCount == 0 ? false : null),
          onChanged: () => onChanged(!all),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            all ? l10n.cartDeselectAll : l10n.cartSelectAll,
            style: context.textStyles.titleSmall,
          ),
        ),
        Text(
          l10n.cartSelectedN(selectedCount),
          style: context.textStyles.bodySmall?.copyWith(
            color: context.appColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

class _FlatItemRow extends StatelessWidget {
  const _FlatItemRow({
    required this.item,
    this.onQuantity,
    this.selected,
    this.onToggle,
  });

  final CartItem item;
  final void Function(CartItem item, int quantity)? onQuantity;

  /// null = không hiện ô chọn.
  final bool? selected;
  final ValueChanged<CartItem>? onToggle;

  @override
  Widget build(BuildContext context) {
    final book = item.listing.book;
    final c = context.appColors;
    final text = context.textStyles;
    final q = item.quantity;
    Widget circle(IconData icon, VoidCallback? onTap, {required bool solid}) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: solid ? context.colors.onSurface : Colors.transparent,
              border: solid
                  ? null
                  : Border.all(color: c.secondaryText, width: 1.2),
            ),
            child: Icon(
              icon,
              size: 16,
              color: solid
                  ? context.colors.surface
                  : (onTap == null ? c.tertiaryText : context.colors.onSurface),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selected != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _TickBox(
                value: selected,
                onChanged: () => onToggle?.call(item),
              ),
            ),
            const SizedBox(width: 6),
          ],
          GestureDetector(
            onTap: () => context.go(Routes.listing(item.listing.id)),
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.fill,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: BookPoster(
                  square: true,
                  title: book.title,
                  author: book.author,
                  coverUrl: book.coverUrl,
                  seed: book.id,
                  width: 40,
                  shadow: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatVnd(item.listing.price),
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (onQuantity != null) ...[
                      circle(
                        Icons.remove_rounded,
                        () => onQuantity!(item, q - 1),
                        solid: false,
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          q.toString().padLeft(2, '0'),
                          textAlign: TextAlign.center,
                          style: text.labelLarge,
                        ),
                      ),
                      circle(
                        Icons.add_rounded,
                        q >= item.listing.stock
                            ? null
                            : () => onQuantity!(item, q + 1),
                        solid: true,
                      ),
                    ] else
                      Text('× $q', style: text.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          if (onQuantity != null)
            GestureDetector(
              onTap: () => onQuantity!(item, 0),
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: c.secondaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thẻ địa chỉ đang chọn: ô ghim bản đồ, người nhận, địa chỉ một dòng, nút Đổi.
class FlatAddressCard extends StatelessWidget {
  const FlatAddressCard({
    super.key,
    required this.address,
    required this.onChange,
    this.onOpenMap,
  });

  final Address address;
  final VoidCallback onChange;

  /// Bấm vào thẻ thì mở sơ đồ vị trí giao hàng.
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    return FlatCard(
      onTap: onOpenMap,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: c.fill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.location_on_rounded, color: MapPalette.pin),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${address.receiver} · ${address.phone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  address.oneLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(color: c.secondaryText),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: Text(l10n.changeAddress)),
        ],
      ),
    );
  }
}

/// Ô icon vuông chọn phương thức thanh toán (tiền mặt / ví / VNPay).
class FlatPayTile extends StatelessWidget {
  const FlatPayTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;

  /// Màu thương hiệu của phương thức: icon trắng nằm trong ô bo màu này.
  final Color color;
  final String label;
  final bool selected;

  /// null = không chọn được (vd. ví không đủ số dư).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final enabled = onTap != null;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: 86,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? context.colors.onSurface : c.separator,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 21, color: CoverPalette.onHero),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: context.textStyles.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ đen lớn giải thích phương thức đang chọn (ví: số dư; VNPay; tiền mặt khi nhận hàng).
class FlatPayCard extends StatelessWidget {
  const FlatPayCard({
    super.key,
    required this.method,
    required this.title,
    required this.hint,
    this.balance,
  });

  final PaymentMethod method;
  final String title;
  final String hint;

  /// Số dư ví đã định dạng (chỉ hiện khi chọn ví).
  final String? balance;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    const fg = CoverPalette.onHero;
    final icon = switch (method) {
      PaymentMethod.cod => Icons.payments_outlined,
      PaymentMethod.wallet => Icons.account_balance_wallet_outlined,
      PaymentMethod.vnpay => Icons.qr_code_2_rounded,
    };
    return AspectRatio(
      aspectRatio: 1.75,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CoverPalette.cardTop, CoverPalette.cardBottom],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      color: fg.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                Icon(icon, color: fg),
              ],
            ),
            const Spacer(),
            if (balance != null) ...[
              Text(
                context.l10n.walletAvailable,
                style: text.bodySmall?.copyWith(
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                balance!,
                style: text.headlineSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ] else
              Text(
                hint,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
