import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';

/// Khung một trang theo style Apple Books.
/// - Desktop: tiêu đề serif lớn trên cùng bên trái, hành động góc phải.
/// - Mobile: thanh đầu có nút quay lại tròn + tiêu đề ở giữa, kẻ mảnh bên dưới.
/// Nội dung truyền qua [slivers] (linh hoạt) hoặc [children] (cột thường).
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.slivers,
    this.children,
    this.showBack,
    this.bottomBar,
    this.onRefresh,
    this.contentPadding,
  }) : assert(slivers != null || children != null);

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<Widget>? slivers;
  final List<Widget>? children;

  /// null = tự quyết theo việc có trang để quay lại hay không.
  final bool? showBack;
  final Widget? bottomBar;
  final Future<void> Function()? onRefresh;

  /// Lề nội dung. Mặc định: lề trang desktop / 20 trên mobile.
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final compact = context.windowSize.isCompact;
    final canBack = showBack ?? (GoRouter.of(context).canPop());
    final pad =
        contentPadding ??
        (compact
            ? const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, 120)
            : const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                0,
                AppSpacing.pageX + 12,
                AppSpacing.xxl,
              ));

    final body = <Widget>[
      if (!compact)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageX,
            AppSpacing.pageTop,
            AppSpacing.pageX + 12,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: _DesktopHeader(
              title: title,
              subtitle: subtitle,
              actions: actions,
              canBack: canBack,
            ),
          ),
        ),
      if (compact && subtitle != null)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad.left, AppSpacing.md, pad.right, 0),
          sliver: SliverToBoxAdapter(
            child: Text(subtitle!, style: context.textStyles.bodySmall),
          ),
        ),
      ...?slivers,
      if (children != null)
        SliverPadding(
          padding: pad,
          sliver: SliverList.list(children: children!),
        ),
    ];

    Widget scroll = CustomScrollView(slivers: body);
    if (onRefresh != null) {
      scroll = RefreshIndicator(onRefresh: onRefresh!, child: scroll);
    }

    return Scaffold(
      appBar: compact
          ? _MobileHeader(title: title, actions: actions, canBack: canBack)
          : null,
      body: scroll,
      bottomNavigationBar: bottomBar,
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.title,
    this.subtitle,
    required this.actions,
    required this.canBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool canBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canBack) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: CircleBackButton(onPressed: () => context.pop()),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textStyles.displaySmall),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle!,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.appColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget implements PreferredSizeWidget {
  const _MobileHeader({
    required this.title,
    required this.actions,
    required this.canBack,
  });

  final String title;
  final List<Widget> actions;
  final bool canBack;

  @override
  Size get preferredSize => const Size.fromHeight(57);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.appColors.separator),
          ),
        ),
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleLarge,
                ),
              ),
              if (canBack)
                Positioned(
                  left: 12,
                  child: CircleBackButton(onPressed: () => context.pop()),
                ),
              if (actions.isNotEmpty)
                Positioned(
                  right: 8,
                  child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hành động chính ở đầu trang ([AppPage.actions]): nút viên thuốc có chữ trên desktop,
/// nút tròn chỉ có biểu tượng trên mobile (thanh đầu hẹp, tránh đè tiêu đề).
class HeaderAction extends StatelessWidget {
  const HeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// false → kiểu phụ (chữ, không nền) trên desktop.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (context.windowSize.isCompact) {
      return IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon),
        style: primary
            ? IconButton.styleFrom(
                backgroundColor: context.colors.onSurface,
                foregroundColor: context.colors.surface,
              )
            : null,
      );
    }
    final child = Text(label);
    final iconWidget = Icon(icon, size: 18);
    return primary
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: iconWidget,
            label: child,
          )
        : TextButton.icon(onPressed: onPressed, icon: iconWidget, label: child);
  }
}

/// Nút quay lại tròn có viền mảnh (như mockup mobile).
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.back,
      child: Material(
        shape: CircleBorder(
          side: BorderSide(color: context.appColors.separator),
        ),
        color: context.colors.surface,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.chevron_left_rounded, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Nút "•••" tròn trắng (góc phải trang desktop) hoặc dấu ba chấm nhỏ dưới poster.
class DotsButton extends StatelessWidget {
  const DotsButton({
    super.key,
    required this.items,
    this.onSelected,
    this.compact = false,
  });

  final List<PopupMenuEntry<String>> items;
  final ValueChanged<String>? onSelected;

  /// true: ba chấm xám nhỏ dưới poster; false: nút tròn nổi.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.more_horiz_rounded,
      size: compact ? 20 : 22,
      color: compact ? context.appColors.secondaryText : null,
    );
    return PopupMenuButton<String>(
      tooltip: context.l10n.moreActions,
      itemBuilder: (_) => items,
      onSelected: onSelected,
      padding: EdgeInsets.zero,
      child: compact
          ? Padding(padding: const EdgeInsets.all(2), child: icon)
          : Container(
              width: 44,
              height: 30,
              decoration: ShapeDecoration(
                color: context.colors.surface,
                shape: const StadiumBorder(),
                shadows: [
                  BoxShadow(
                    color: context.appColors.posterShadow.withValues(
                      alpha: 0.25,
                    ),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: icon,
            ),
    );
  }
}

/// Tiêu đề kệ / khối: "Truyện ngắn ›". Bấm được khi có [onTap].
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onTap, this.trailing});

  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(
      TextSpan(
        text: title,
        children: [
          if (onTap != null)
            TextSpan(
              text: '  ›',
              style: TextStyle(
                color: context.appColors.tertiaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      style: context.textStyles.headlineSmall,
    );
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: onTap == null
                ? text
                : InkWell(
                    onTap: onTap,
                    borderRadius: AppRadius.item,
                    child: text,
                  ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Badge viên thuốc nhỏ: "MỚI" (xanh), "ĐẤU GIÁ" (đỏ).
class PillBadge extends StatelessWidget {
  const PillBadge(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  factory PillBadge.newItem(BuildContext context) =>
      PillBadge(context.l10n.badgeNew, color: context.appColors.badgeNew);
  factory PillBadge.auction(BuildContext context) =>
      PillBadge(context.l10n.badgeAuction, color: context.appColors.live);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: ShapeDecoration(
        color: color ?? context.appColors.badgeNew,
        shape: const StadiumBorder(),
      ),
      child: Text(
        text,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colors.surface,
        ),
      ),
    );
  }
}

/// Giá VND. [strong]: in đậm màu chữ chính.
class PriceText extends StatelessWidget {
  const PriceText(this.amount, {super.key, this.style, this.strong = true});

  final int amount;
  final TextStyle? style;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.textStyles.bodyMedium;
    return Text(
      formatVnd(amount),
      style: base?.copyWith(
        fontWeight: strong ? FontWeight.w700 : null,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Trạng thái rỗng / chưa có dữ liệu.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.menu_book_outlined,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: context.appColors.tertiaryText),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.textStyles.titleMedium,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.appColors.secondaryText,
                  ),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppSpacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Khối nội dung nền xám nhạt bo góc (thông tin, biểu mẫu, tóm tắt).
class InfoPanel extends StatelessWidget {
  const InfoPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appColors.sidebar,
        borderRadius: AppRadius.card,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Ô lựa chọn một trong nhiều (địa chỉ, phương thức thanh toán, mức cọc…):
/// nền xám nhạt, viền đậm + dấu tích khi được chọn.
class SelectTile extends StatelessWidget {
  const SelectTile({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// null = không chọn được (vd số dư ví không đủ).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: c.sidebar,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(
            color: selected ? c.selected : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(
            borderRadius: AppRadius.card,
          ),
          onTap: onTap,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: context.textStyles.titleMedium),
                        if (subtitle != null)
                          Text(subtitle!, style: context.textStyles.bodySmall),
                      ],
                    ),
                  ),
                  ?trailing,
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? c.selected : c.tertiaryText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
