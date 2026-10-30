import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';

/// Một cuốn đứng trên kệ kính.
class ShelfEntry {
  const ShelfEntry({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.price,
    this.onTap,
  });

  final String id;
  final String title;
  final String author;
  final String? coverUrl;

  /// Giá đã định dạng; hiện thành chip nhỏ ở góc dưới bìa (kệ không có chữ bên dưới bìa).
  final String? price;
  final VoidCallback? onTap;
}

/// Một kệ sách: tiêu đề (tên thể loại), "n cuốn" và hai mũi tên cuộn, rồi một hàng bìa đứng trên **tấm ván kính
/// màu** có hai đinh vít. Bìa vuông góc, cao theo ảnh thật, đáy các cuốn canh thẳng trên ván và nhìn xuyên
/// qua ván. Chỉ có bìa: bấm vào cuốn nào thì mở chi tiết (có tên, giá).
class GlassShelf extends StatefulWidget {
  const GlassShelf({
    super.key,
    required this.title,
    required this.entries,
    required this.color,
    this.onTitleTap,
  });

  final String title;
  final List<ShelfEntry> entries;

  /// Màu tấm ván của kệ.
  final Color color;
  final VoidCallback? onTitleTap;

  @override
  State<GlassShelf> createState() => _GlassShelfState();
}

class _GlassShelfState extends State<GlassShelf> {
  final _scroll = ScrollController();

  /// Chiều rộng một cuốn trên kệ và khoảng cách giữa các cuốn.
  static const _bookW = 96.0;
  static const _gap = 14.0;

  /// Cao tối đa của vùng đặt sách: bìa cao nhất (tỉ lệ ~0,5 → cao gấp đôi rộng) vẫn lọt.
  static const _stageH = 176.0;
  static const _plankH = 22.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _page(int dir) {
    if (!_scroll.hasClients) return;
    final step = _scroll.position.viewportDimension * 0.8 * dir;
    _scroll.animateTo(
      (_scroll.offset + step).clamp(0.0, _scroll.position.maxScrollExtent),
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.appColors;
    final text = context.textStyles;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final plank = widget.color.withValues(alpha: dark ? 0.4 : 0.52);

    Widget arrow(IconData icon, String tip, int dir) => InkResponse(
      radius: 18,
      onTap: () => _page(dir),
      child: Tooltip(
        message: tip,
        child: Icon(icon, size: 20, color: c.secondaryText),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onTitleTap,
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Text(
                l10n.shelfCount(widget.entries.length),
                style: text.bodySmall?.copyWith(color: c.secondaryText),
              ),
              const SizedBox(width: 10),
              arrow(Icons.chevron_left_rounded, l10n.shelfPrev, -1),
              const SizedBox(width: 6),
              arrow(Icons.chevron_right_rounded, l10n.shelfNext, 1),
            ],
          ),
        ),
        SizedBox(
          height: _stageH + _plankH,
          child: Stack(
            children: [
              // Sách đứng trên ván: đáy canh thẳng ở mép dưới vùng đặt sách, xuyên xuống ván một đoạn.
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _stageH,
                child: ListView.separated(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.entries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, i) =>
                      _ShelfBook(entry: widget.entries[i], width: _bookW),
                ),
              ),
              // Tấm ván kính màu nằm TRÊN đáy bìa, nên đáy bìa thấy xuyên qua.
              Positioned(
                left: 12,
                right: 12,
                bottom: 0,
                height: _plankH + 14,
                child: IgnorePointer(
                  child: _Plank(color: plank, screw: c.separator),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShelfBook extends StatelessWidget {
  const _ShelfBook({required this.entry, required this.width});

  final ShelfEntry entry;
  final double width;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: entry.onTap,
      child: SizedBox(
        width: width,
        child: Align(
          alignment: Alignment.bottomCenter,
          // Đẩy bìa xuống để đáy chìm vào tấm ván một đoạn (như bìa dựa vào ván kính).
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Stack(
              children: [
                BookPoster(
                  square: true,
                  title: entry.title,
                  author: entry.author,
                  coverUrl: entry.coverUrl,
                  seed: entry.id,
                  width: width,
                ),
                if (entry.price != null)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      color: CoverPalette.scrim.withValues(alpha: 0.72),
                      child: Text(
                        entry.price!,
                        style: text.labelSmall?.copyWith(
                          color: CoverPalette.onHero,
                          fontWeight: FontWeight.w700,
                        ),
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
}

/// Tấm ván: dải kính màu bo nhẹ, vệt sáng ở mép trên, hai đinh vít hai đầu.
class _Plank extends StatelessWidget {
  const _Plank({required this.color, required this.screw});

  final Color color;
  final Color screw;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color,
          border: Border.all(
            color: CoverPalette.onHero.withValues(alpha: 0.35),
          ),
          boxShadow: const [
            BoxShadow(
              color: ShelfPalette.shadow,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Screw(color: screw),
            _Screw(color: screw),
          ],
        ),
      ),
    );
  }
}

class _Screw extends StatelessWidget {
  const _Screw({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CoverPalette.onHero.withValues(alpha: 0.7),
        border: Border.all(color: color, width: 1),
      ),
    ),
  );
}
