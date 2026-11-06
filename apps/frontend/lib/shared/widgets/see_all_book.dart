import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/cover_color.dart';

/// "Cuốn sách giả" ở cuối một kệ: cùng cỡ một bìa (tỉ lệ 2:3), nền màu theo [title] (tên thể loại), có gáy và bóng như
/// sách thật, ghi tên thể loại và [caption] ("Xem tất cả N cuốn"). Bấm vào để xem hết sách của thể loại.
/// [belowHeight]: chiều cao dòng tên + giá của các cuốn thật đứng cạnh, để đáy các cuốn thẳng hàng.
class SeeAllBookCard extends StatelessWidget {
  const SeeAllBookCard({
    super.key,
    required this.title,
    required this.caption,
    required this.onTap,
    this.belowHeight = 68,
  });

  final String title;
  final String caption;
  final VoidCallback onTap;
  final double belowHeight;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final color = CoverColor.fallback(title);
    return LayoutBuilder(
      builder: (context, box) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: box.maxWidth,
                height: box.maxWidth / CoverAspect.fallback,
                decoration: BoxDecoration(
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.posterShadow,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 6,
                      child: ColoredBox(
                        color: HSLColor.fromColor(color)
                            .withLightness(
                              (HSLColor.fromColor(color).lightness - 0.1).clamp(
                                0.04,
                                1.0,
                              ),
                            )
                            .toColor(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelLarge?.copyWith(
                              color: CoverPalette.onHero,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: CoverPalette.onHero,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            caption,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(
                              color: CoverPalette.onHero.withValues(alpha: 0.9),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: belowHeight),
            ],
          ),
        ),
      ),
    );
  }
}
