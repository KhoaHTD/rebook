import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/router/routes.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Hai khu của app: mua bán sách giá cố định và sàn đấu giá. Mỗi khu có khung, màu và trang chủ riêng.
enum AppMode { books, auction }

/// Công tắc hai nấc "Mua sách | Đấu giá". Bấm sang nấc kia là đổi cả khung giao diện
/// (sidebar / tab bar / bảng màu). Màu lấy từ theme hiện hành nên khớp với khu đang đứng.
class ModeSwitch extends StatelessWidget {
  const ModeSwitch({super.key, required this.mode, this.onHero = false});

  final AppMode mode;

  /// Đặt trên nền màu của bìa (đầu trang chủ điện thoại): nền kính trong, nấc đang chọn trắng chữ tối.
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final l10n = context.l10n;
    Widget segment(AppMode m, IconData icon, String label, String path) {
      final on = mode == m;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          child: InkWell(
            borderRadius: AppRadius.chip,
            onTap: on ? null : () => context.go(path),
            child: AnimatedContainer(
              duration: AppDurations.fast,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: AppRadius.chip,
                color: on
                    ? (onHero ? CoverPalette.onHero : c.selected)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: on
                        ? (onHero ? CoverPalette.onHeroInk : c.onSelected)
                        : (onHero ? CoverPalette.onHero : c.secondaryText),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: on
                            ? (onHero ? CoverPalette.onHeroInk : c.onSelected)
                            : (onHero ? CoverPalette.onHero : c.secondaryText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: AppRadius.chip,
        color: onHero ? CoverPalette.onHero.withValues(alpha: 0.18) : c.fill,
        border: Border.all(
          color: onHero
              ? CoverPalette.onHero.withValues(alpha: 0.28)
              : c.glassBorder,
        ),
      ),
      child: Row(
        children: [
          segment(
            AppMode.books,
            Icons.menu_book_rounded,
            l10n.modeBooks,
            Routes.home,
          ),
          segment(
            AppMode.auction,
            Icons.gavel_rounded,
            l10n.modeAuction,
            Routes.auctions,
          ),
        ],
      ),
    );
  }
}
