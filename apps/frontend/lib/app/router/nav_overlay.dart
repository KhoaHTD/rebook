import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/sidebar.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/core/settings/app_settings_controller.dart';
import 'package:book_marketplace/shared/layout/breakpoints.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Cho các mục trong sidebar trượt biết cách đóng sidebar sau khi bấm (xem [NavOverlay]).
class NavPanelScope extends InheritedWidget {
  const NavPanelScope({super.key, required this.close, required super.child});

  final VoidCallback close;

  /// Đóng sidebar trượt nếu đang nằm trong [NavOverlay]; ngoài đó (sidebar web quản trị) không làm gì.
  static void closeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<NavPanelScope>()?.close();

  @override
  bool updateShouldNotify(NavPanelScope old) => false;
}

/// Điều hướng của app người dùng: một nút kính tròn ở góc dưới; bấm vào thì sidebar kính trượt ra
/// từ cùng phía, đè lên nội dung. Kéo nút sang nửa bên kia (hoặc đổi trong Cài đặt) để đổi phía.
class NavOverlay extends ConsumerStatefulWidget {
  const NavOverlay({
    super.key,
    required this.child,
    required this.panel,
    required this.icon,
    this.bar,
    this.showButton = true,
    this.accent = false,
  });

  /// Nội dung trang (khung điều hướng của go_router).
  final Widget child;

  /// Ruột sidebar (công tắc khu, các mục, tài khoản): dùng ở máy tính bảng và desktop.
  final Widget panel;

  /// Thanh tab ngang liquid glass: ở điện thoại, bấm nút thì nó nở lên từ đáy thay cho sidebar.
  final Widget? bar;

  /// Biểu tượng của mục đang đứng, hiện trên nút.
  final IconData icon;

  /// false ở các trang con (chi tiết, thanh toán…) để nút không đè lên thanh mua hàng.
  final bool showButton;

  /// Nút tô màu nhấn của khu (khu đấu giá: vàng đồng) thay cho kính trong.
  final bool accent;

  static const _button = 52.0;
  static const _margin = 18.0;

  @override
  ConsumerState<NavOverlay> createState() => _NavOverlayState();
}

class _NavOverlayState extends ConsumerState<NavOverlay> {
  bool _open = false;

  /// Panel được dựng khi mở và đến hết hoạt ảnh đóng (để khỏi tốn kính mờ lúc không dùng).
  bool _mounted = false;
  double _dx = 0;

  void _openPanel() {
    setState(() => _mounted = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _open = true);
    });
  }

  void _close() {
    if (_open) setState(() => _open = false);
  }

  void _endDrag(double screenWidth, NavSide side) {
    final onRight = side == NavSide.right;
    final left =
        (onRight
            ? screenWidth - NavOverlay._margin - NavOverlay._button
            : NavOverlay._margin) +
        _dx;
    final center = left + NavOverlay._button / 2;
    final next = center > screenWidth / 2 ? NavSide.right : NavSide.left;
    setState(() => _dx = 0);
    if (next != side) {
      ref.read(appSettingsControllerProvider.notifier).setNavSide(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final side = ref.watch(
      appSettingsControllerProvider.select((s) => s.navSide),
    );
    final onRight = side == NavSide.right;
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final panelW = math.min(SidebarPanel.width, screenW * 0.86);
    final hidden = -panelW;
    final useBar = widget.bar != null && context.windowSize.isCompact;

    // Biểu tượng thanh trạng thái theo nền của khu (sáng → biểu tượng tối). Trang chủ điện thoại tự đặt lại khi nền màu còn ở đầu trang.
    final style = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style,
      child: PopScope(
        canPop: !_open,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _close();
        },
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (_mounted)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: AnimatedOpacity(
                    duration: AppDurations.normal,
                    opacity: _open ? 1 : 0,
                    child: ColoredBox(
                      color: CoverPalette.scrim.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            if (_mounted && useBar)
              AnimatedPositioned(
                duration: AppDurations.normal,
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                bottom: _open ? 0 : -140,
                onEnd: () {
                  if (!_open && mounted) setState(() => _mounted = false);
                },
                child: FlatScope(
                  flat: false,
                  child: NavPanelScope(close: _close, child: widget.bar!),
                ),
              ),
            if (_mounted && !useBar)
              AnimatedPositioned(
                duration: AppDurations.normal,
                curve: Curves.easeOutCubic,
                left: onRight ? null : (_open ? 0 : hidden),
                right: onRight ? (_open ? 0 : hidden) : null,
                top: 0,
                bottom: 0,
                width: panelW,
                onEnd: () {
                  if (!_open && mounted) setState(() => _mounted = false);
                },
                child: FlatScope(
                  flat: false,
                  child: NavPanelScope(
                    close: _close,
                    child: SidebarPanel(side: side, child: widget.panel),
                  ),
                ),
              ),
            if (widget.showButton && !_open)
              Positioned(
                left:
                    (onRight
                        ? screenW - NavOverlay._margin - NavOverlay._button
                        : NavOverlay._margin) +
                    _dx,
                bottom: NavOverlay._margin + media.padding.bottom,
                width: NavOverlay._button,
                height: NavOverlay._button,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) => setState(
                    () => _dx = (_dx + d.delta.dx).clamp(-screenW, screenW),
                  ),
                  onHorizontalDragEnd: (_) => _endDrag(screenW, side),
                  child: Semantics(
                    button: true,
                    label: context.l10n.navMenu,
                    child: FlatScope(
                      flat: false,
                      child: Glass.circle(
                        tint: widget.accent ? context.appColors.selected : null,
                        onTap: _openPanel,
                        child: Icon(
                          widget.icon,
                          size: 24,
                          color: widget.accent
                              ? context.appColors.onSelected
                              : context.colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
