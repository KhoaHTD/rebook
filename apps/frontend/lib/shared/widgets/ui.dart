import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/utils/formatters.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/layout/shell_inset.dart';
import 'package:book_marketplace/shared/widgets/admin_scope.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';
import 'package:book_marketplace/shared/widgets/glass_menu.dart';

/// Khung một trang theo style Liquid Glass (trang tự vẽ nền màu loang nên luôn đặc khi chuyển trang).
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
    this.background,
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

  /// Nền thay cho nền màu loang (vd. [BookBackdrop] ở trang chi tiết sách). Đứng yên khi cuộn.
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    final canBack = showBack ?? (GoRouter.of(context).canPop());
    if (AdminScope.active(context)) return _adminPage(context, canBack);
    final compact = context.windowSize.isCompact;
    final pad =
        contentPadding ??
        (compact
            ? EdgeInsets.fromLTRB(
                20,
                AppSpacing.md,
                20,
                bottomBar == null ? 120 : 260,
              )
            : const EdgeInsets.fromLTRB(
                AppSpacing.pageX,
                0,
                AppSpacing.pageX + 12,
                AppSpacing.xxl,
              ));

    final body = <Widget>[
      // Mobile: nội dung cuộn bên dưới thanh đầu bằng kính.
      if (compact)
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.paddingOf(context).top + _MobileHeader.height,
          ),
        ),
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

    // Desktop: trang phủ hết bề rộng, sidebar kính đè lên mép trái → chừa lề trái đúng bằng sidebar
    // để nội dung thường nằm bên phải sidebar (chỉ khối cố ý tràn như băng chuyền mới chạy xuống dưới).
    final inset = compact ? 0.0 : ShellInset.of(context);
    Widget scroll = CustomScrollView(
      slivers: inset == 0
          ? body
          : [
              for (final s in body)
                SliverPadding(
                  padding: EdgeInsets.only(left: inset),
                  sliver: s,
                ),
            ],
    );
    if (onRefresh != null) {
      scroll = RefreshIndicator(onRefresh: onRefresh!, child: scroll);
    }

    // Trang tự vẽ nền loang (khớp toạ độ với nền khung app) để trang luôn đặc khi chuyển trang.
    final page = Scaffold(
      extendBodyBehindAppBar: compact,
      // Có thanh kính nổi ở đáy → nội dung cuộn xuống dưới lớp kính.
      extendBody: bottomBar != null,
      appBar: compact
          ? _MobileHeader(title: title, actions: actions, canBack: canBack)
          : null,
      body: scroll,
      bottomNavigationBar: bottomBar == null || inset == 0
          ? bottomBar
          : Padding(
              padding: EdgeInsets.only(left: inset),
              child: bottomBar,
            ),
    );
    // Trang tự vẽ nền (màu loang khớp toạ độ với nền khung app, hoặc [background]) nên luôn đặc khi chuyển trang.
    return AmbientBackground(
      child: background == null
          ? page
          : Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: background!),
                page,
              ],
            ),
    );
  }
}

extension on AppPage {
  /// Trang quản trị: thanh tiêu đề phẳng màu trắng + nội dung trên nền xám nhạt.
  Widget _adminPage(BuildContext context, bool canBack) {
    final text = context.textStyles;
    final onMenu = AdminScope.menuOf(context);
    final compact = onMenu != null;
    final gutter = compact ? 16.0 : 24.0;
    Widget scroll = CustomScrollView(
      slivers: [
        ...?slivers,
        if (children != null)
          SliverPadding(
            padding:
                contentPadding ??
                EdgeInsets.fromLTRB(gutter, compact ? 16 : 20, gutter, 32),
            sliver: SliverList.list(children: children!),
          ),
      ],
    );
    if (onRefresh != null) {
      scroll = RefreshIndicator(onRefresh: onRefresh!, child: scroll);
    }
    return ColoredBox(
      color: AdminPalette.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            // Trên điện thoại thanh đầu trang nằm dưới thanh trạng thái (web: inset = 0).
            height: 60 + MediaQuery.paddingOf(context).top,
            padding: EdgeInsets.fromLTRB(
              gutter - (compact ? 8 : 0),
              MediaQuery.paddingOf(context).top,
              gutter,
              0,
            ),
            decoration: const BoxDecoration(
              color: AdminPalette.card,
              border: Border(bottom: BorderSide(color: AdminPalette.line)),
            ),
            child: Row(
              children: [
                if (onMenu != null)
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, size: 22),
                    onPressed: onMenu,
                  ),
                if (canBack)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    onPressed: () => context.pop(),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (compact ? text.titleLarge : text.headlineSmall)
                                  ?.copyWith(
                                    fontFamily: AppFonts.serif,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      if (subtitle != null && !compact) ...[
                        const SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              color: AdminPalette.muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                for (final a in actions) ...[
                  const SizedBox(width: AppSpacing.sm),
                  a,
                ],
              ],
            ),
          ),
          Expanded(
            child: Material(color: Colors.transparent, child: scroll),
          ),
        ],
      ),
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

  static const height = 57.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    // Thanh đầu bằng kính: làm mờ nội dung cuộn phía dưới, kẻ sáng mảnh ở đáy.
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.glassTop, c.glassBottom],
            ),
            border: Border(bottom: BorderSide(color: c.separator, width: 0.5)),
          ),
          child: SafeArea(
            bottom: false,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
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
    // Quản trị trên điện thoại: nút tròn đen thay cho nút xanh của app người mua.
    final adminCompact = AdminScope.menuOf(context) != null;
    if (adminCompact || context.windowSize.isCompact) {
      return IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon),
        style: primary
            ? IconButton.styleFrom(
                backgroundColor: adminCompact
                    ? AdminPalette.ink
                    : context.appColors.tint,
                foregroundColor: adminCompact
                    ? AdminPalette.card
                    : context.colors.onPrimary,
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

/// Nút quay lại tròn bằng kính.
class CircleBackButton extends StatelessWidget {
  const CircleBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.back,
      child: SizedBox.square(
        dimension: 40,
        child: Glass.circle(
          onTap: onPressed,
          child: const Center(
            child: Icon(Icons.chevron_left_rounded, size: 26),
          ),
        ),
      ),
    );
  }
}

/// Nút "•••" tròn bằng kính (góc phải trang) hoặc dấu ba chấm nhỏ dưới poster.
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
    return GlassMenuButton<String>(
      tooltip: context.l10n.moreActions,
      // Giữ nhận `PopupMenuItem` từ nơi gọi; hiển thị bằng menu kính bo góc.
      items: [
        for (final e in items)
          if (e is PopupMenuItem<String> && e.value != null)
            GlassMenuItem<String>(
              value: e.value!,
              child: e.child,
              enabled: e.enabled,
            ),
      ],
      onSelected: (v) => onSelected?.call(v),
      child: compact
          ? Padding(padding: const EdgeInsets.all(2), child: icon)
          : SizedBox.square(
              dimension: 40,
              child: Glass.circle(child: Center(child: icon)),
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

/// Chip kính nhỏ: "MỚI" (kính tối), "ĐẤU GIÁ" (kính đỏ). Thường đặt lên góc bìa ([BookPoster.badge]).
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
    final c = context.appColors;
    final base = color ?? c.badgeNew;
    return ClipRRect(
      borderRadius: AppRadius.chip,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: ShapeDecoration(
            color: base.a >= 0.99 ? base.withValues(alpha: 0.72) : base,
            shape: StadiumBorder(
              side: BorderSide(
                color: c.glassBorder.withValues(alpha: 0.45),
                width: 0.5,
              ),
            ),
          ),
          child: Text(
            text,
            style: context.textStyles.labelSmall?.copyWith(color: c.onSelected),
          ),
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

/// Khối nội dung bằng kính trong (thông tin, biểu mẫu, tóm tắt). Không làm mờ để cuộn mượt.
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
    return Glass(blur: false, padding: padding, child: child);
  }
}

/// Ô lựa chọn một trong nhiều (địa chỉ, phương thức thanh toán, mức cọc…):
/// nền kính trong, viền xanh + dấu tích khi được chọn.
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
