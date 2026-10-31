import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Hai khu của app: mua bán sách giá cố định và sàn đấu giá. Mỗi khu có khung, màu và trang chủ riêng.
enum AppMode { books, auction }

/// Hiệu ứng "loang": khi đổi khu, giao diện khu mới lan ra như một vòng tròn từ chỗ vừa bấm
/// và phủ lên giao diện cũ. Điểm bắt đầu được nhớ ở đây trong lúc router dựng trang mới.
abstract final class ModeReveal {
  static Offset? _origin;

  /// Điểm loang bắt đầu (toạ độ màn hình), null nếu không phải do bấm nút đổi khu.
  static Offset? get origin => _origin;

  /// Đổi sang [target]; vòng loang bắt đầu từ tâm widget của [context] (nút vừa bấm).
  static void go(BuildContext context, AppMode target) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      _origin = box.localToGlobal(box.size.center(Offset.zero));
      // Hết hiệu lực sau khi hiệu ứng chạy xong, để lần đổi trang khác không bị loang nhầm.
      Future<void>.delayed(const Duration(seconds: 2), () => _origin = null);
    }
    context.go(target == AppMode.auction ? Routes.auctions : Routes.home);
  }

  /// Bọc trang mới: có điểm bắt đầu thì hiện dần theo vòng tròn, không thì hiện thẳng.
  static Widget transition(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    final origin = _origin;
    if (origin == null) return child;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => ClipPath(
        clipper: _CircleClipper(
          origin,
          Curves.easeInOutCubic.transform(animation.value),
        ),
        child: child,
      ),
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  _CircleClipper(this.center, this.t);

  final Offset center;
  final double t;

  @override
  Path getClip(Size size) {
    final far = math.max(
      math.max(center.distance, (center - Offset(size.width, 0)).distance),
      math.max(
        (center - Offset(0, size.height)).distance,
        (center - Offset(size.width, size.height)).distance,
      ),
    );
    return Path()..addOval(Rect.fromCircle(center: center, radius: far * t));
  }

  @override
  bool shouldReclip(_CircleClipper old) => old.t != t || old.center != center;
}

/// Nút tròn đổi khu: búa đấu giá ở khu mua sách, cửa hàng ở khu đấu giá. Bấm là đổi khu với hiệu ứng loang.
class ModeButton extends StatelessWidget {
  const ModeButton({super.key, required this.mode, this.onHero = false});

  /// Khu đang đứng (nút dẫn sang khu còn lại).
  final AppMode mode;

  /// Đặt trên nền màu của bìa (đầu trang chủ điện thoại): nền trong, biểu tượng trắng.
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final toAuction = mode == AppMode.books;
    final fg = onHero ? CoverPalette.onHero : context.colors.onSurface;
    return Builder(
      builder: (context) => Semantics(
        button: true,
        label: toAuction ? l10n.modeToAuction : l10n.modeBackToBooks,
        child: Tooltip(
          message: toAuction ? l10n.modeToAuction : l10n.modeBackToBooks,
          child: InkResponse(
            radius: 26,
            onTap: () => ModeReveal.go(
              context,
              toAuction ? AppMode.auction : AppMode.books,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onHero
                    ? CoverPalette.onHero.withValues(alpha: 0.18)
                    : context.appColors.fill,
                border: Border.all(
                  color: onHero
                      ? CoverPalette.onHero.withValues(alpha: 0.28)
                      : context.appColors.glassBorder,
                ),
              ),
              child: Icon(
                toAuction ? Icons.gavel_rounded : Icons.storefront_rounded,
                size: 22,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
