import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/book_poster.dart';
import 'package:book_marketplace/shared/widgets/cover_color.dart';

/// Một cuốn (hoặc lô) hiện trên trang chủ điện thoại: ở hàng bìa lớn hoặc trong một kệ.
class CoverFlowEntry {
  const CoverFlowEntry({
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

  /// Giá đã định dạng (hiện dưới bìa trong kệ); null thì không hiện dòng giá.
  final String? price;
  final VoidCallback? onTap;
}

/// Một kệ: nhãn viết hoa nhỏ kèm đường kẻ, rồi một hàng bìa cuộn ngang.
class CoverFlowShelf {
  const CoverFlowShelf(this.label, this.entries);

  final String label;
  final List<CoverFlowEntry> entries;
}

/// Trang chủ điện thoại: nửa trên là **một màu chủ đạo của bìa** đang chọn (đổi mượt khi lướt) với hàng bìa
/// lớn (cuốn giữa to nhất); nửa dưới là tờ giấy bo góc chứa tab và các kệ sách. Kéo lên thì tờ giấy trượt
/// che nửa trên và phủ kín màn hình, chỉ còn thanh tiêu đề mỏng. Bìa vuông góc, không kính.
class CoverFlowHome extends StatefulWidget {
  const CoverFlowHome({
    super.key,
    required this.title,
    required this.trailing,
    required this.hero,
    required this.tabs,
    required this.tabIndex,
    required this.onTab,
    required this.shelves,
    required this.emptyText,
  });

  final String title;

  /// Nút bên phải tiêu đề (nút đổi khu); tham số cho biết đang đặt trên nền màu (true) hay trên tờ giấy (false).
  final Widget Function(bool onHero) trailing;

  /// Các cuốn ở hàng bìa lớn (chừng 5 cuốn).
  final List<CoverFlowEntry> hero;
  final List<String> tabs;
  final int tabIndex;
  final ValueChanged<int> onTab;
  final List<CoverFlowShelf> shelves;
  final String emptyText;

  @override
  State<CoverFlowHome> createState() => _CoverFlowHomeState();
}

class _CoverFlowHomeState extends State<CoverFlowHome> {
  static const _radius = 28.0;
  static const _pagesHeight = 290.0;

  final _scroll = ScrollController();
  final _pages = PageController(viewportFraction: 0.5);
  int _index = 0;
  final _colors = <String, Color>{};

  @override
  void initState() {
    super.initState();
    _warm();
  }

  @override
  void didUpdateWidget(CoverFlowHome old) {
    super.didUpdateWidget(old);
    if (_index >= widget.hero.length) _index = 0;
    _warm();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pages.dispose();
    super.dispose();
  }

  /// Tính màu chủ đạo của cuốn đang chọn và hai cuốn kề bên (để lướt tới là có màu ngay).
  void _warm() {
    for (var i = _index - 1; i <= _index + 1; i++) {
      if (i < 0 || i >= widget.hero.length) continue;
      final e = widget.hero[i];
      if (_colors.containsKey(e.id)) continue;
      CoverColor.of(url: e.coverUrl, seed: e.id).then((c) {
        if (mounted) setState(() => _colors[e.id] = c);
      });
    }
  }

  Color _color(CoverFlowEntry? e) => e == null
      ? CoverColor.fallback('home')
      : _colors[e.id] ?? CoverColor.peek(url: e.coverUrl, seed: e.id);

  static Color _darker(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.12).clamp(0.06, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final paper = context.colors.surface;
    final safeTop = MediaQuery.paddingOf(context).top;
    final heroH = safeTop + 446;
    final current = widget.hero.isEmpty
        ? null
        : widget.hero[_index.clamp(0, widget.hero.length - 1)];
    final color = _color(current);

    // Biểu tượng thanh trạng thái: sáng khi nền màu còn ở đầu trang, theo nền tờ giấy khi nó đã phủ kín.
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _scroll,
      builder: (context, child) {
        final off = _scroll.hasClients ? _scroll.offset : 0.0;
        final onHero = off < heroH - safeTop - 40;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: onHero || dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: child!,
        );
      },
      child: LayoutBuilder(
        builder: (context, box) {
          return Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: paper)),
              CustomScrollView(
                controller: _scroll,
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: heroH)),
                  SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: box.maxHeight),
                      child: _Paper(
                        color: paper,
                        radius: _radius,
                        child: _paperContent(context, box.maxWidth),
                      ),
                    ),
                  ),
                ],
              ),
              // Nửa trên nằm TRÊN khung cuộn nhưng bị cắt theo mép tờ giấy, nên tờ giấy trượt lên "che" nó
              // và chạm vào hàng bìa vẫn tới được hàng bìa.
              AnimatedBuilder(
                animation: _scroll,
                builder: (context, _) {
                  final off = _scroll.hasClients ? _scroll.offset : 0.0;
                  final paperTop = (heroH - off).clamp(0.0, double.infinity);
                  return ClipPath(
                    clipper: _PaperClipper(paperTop, _radius),
                    child: Stack(
                      children: [
                        Positioned(
                          top: off > 0 ? -off * 0.3 : 0,
                          left: 0,
                          right: 0,
                          height: heroH,
                          child: _hero(context, safeTop, color),
                        ),
                      ],
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _scroll,
                builder: (context, _) {
                  final off = _scroll.hasClients ? _scroll.offset : 0.0;
                  final start = heroH - safeTop - 90;
                  final t = ((off - start) / 50).clamp(0.0, 1.0);
                  return Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: t < 0.5,
                      child: Opacity(
                        opacity: t,
                        child: _compactBar(context, paper, safeTop),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _compactBar(BuildContext context, Color paper, double safeTop) {
    return Material(
      color: paper,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, safeTop, 8, 0),
        height: safeTop + 56,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.appColors.separator),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.headlineSmall,
              ),
            ),
            widget.trailing(false),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, double safeTop, Color color) {
    final text = context.textStyles;
    final current = widget.hero.isEmpty ? null : widget.hero[_index];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, _darker(color)],
        ),
      ),
      padding: EdgeInsets.only(top: safeTop + 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineMedium?.copyWith(
                      color: CoverPalette.onHero,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                widget.trailing(true),
                const SizedBox(width: 12),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: _pagesHeight,
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.hero.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _warm();
              },
              itemBuilder: (context, i) => _coverPage(i, widget.hero[i]),
            ),
          ),
          const SizedBox(height: 8),
          if (current != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    current.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: text.titleLarge?.copyWith(
                      color: CoverPalette.onHero,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    current.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      color: CoverPalette.onHero.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _coverPage(int i, CoverFlowEntry e) {
    return AnimatedBuilder(
      animation: _pages,
      builder: (context, _) {
        final page = _pages.hasClients && _pages.position.haveDimensions
            ? (_pages.page ?? _index.toDouble())
            : _index.toDouble();
        final t = (1 - (i - page).abs()).clamp(0.0, 1.0);
        return Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {
              if (i == _index) {
                e.onTap?.call();
              } else {
                _pages.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            child: Transform.scale(
              scale: 0.62 + 0.38 * t,
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: 0.7 + 0.3 * t,
                child: SizedBox(
                  width: 170,
                  height: _pagesHeight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 170,
                      child: BookPoster(
                        square: true,
                        title: e.title,
                        author: e.author,
                        coverUrl: e.coverUrl,
                        seed: e.id,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _paperContent(BuildContext context, double width) {
    final c = context.appColors;
    final text = context.textStyles;
    // 3 cuốn rưỡi: lề trái 20, ba khoảng cách 12, cuốn thứ tư ló một nửa.
    final itemW = (width - 56) / 3.5;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (var i = 0; i < widget.tabs.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: InkResponse(
                      onTap: () => widget.onTab(i),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 2,
                              color: i == widget.tabIndex
                                  ? context.colors.onSurface
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Text(
                          widget.tabs[i],
                          style: text.titleMedium?.copyWith(
                            fontWeight: i == widget.tabIndex
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: i == widget.tabIndex
                                ? context.colors.onSurface
                                : c.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.separator),
          if (widget.shelves.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                widget.emptyText,
                style: text.bodyMedium?.copyWith(color: c.secondaryText),
              ),
            ),
          for (final shelf in widget.shelves) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Text(
                shelf.label.toUpperCase(),
                style: text.labelMedium?.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, indent: 20, endIndent: 20, color: c.separator),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final e in shelf.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _ShelfItem(entry: e, width: itemW),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShelfItem extends StatelessWidget {
  const _ShelfItem({required this.entry, required this.width});

  final CoverFlowEntry entry;
  final double width;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: entry.onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            BookPoster(
              square: true,
              title: entry.title,
              author: entry.author,
              coverUrl: entry.coverUrl,
              seed: entry.id,
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: Text(
                entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(height: 1.2),
              ),
            ),
            SizedBox(
              height: 20,
              child: entry.price == null
                  ? null
                  : Text(
                      entry.price!,
                      maxLines: 1,
                      style: text.labelLarge?.copyWith(
                        color: context.appColors.secondaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tờ giấy: nền theo theme, hai góc trên bo, bóng nhẹ hắt lên nửa trên.
class _Paper extends StatelessWidget {
  const _Paper({
    required this.color,
    required this.radius,
    required this.child,
  });

  final Color color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
    ),
    child: child,
  );
}

/// Phần nửa trên nhìn thấy được: mọi thứ phía trên mép tờ giấy (kể cả hai góc bo, nơi lộ màu nền).
class _PaperClipper extends CustomClipper<Path> {
  _PaperClipper(this.paperTop, this.radius);

  final double paperTop;
  final double radius;

  @override
  Path getClip(Size size) {
    final above = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, paperTop + radius));
    final paper = Path()
      ..addRRect(
        RRect.fromLTRBAndCorners(
          0,
          paperTop,
          size.width,
          size.height + radius,
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
      );
    return Path.combine(PathOperation.difference, above, paper);
  }

  @override
  bool shouldReclip(_PaperClipper old) =>
      old.paperTop != paperTop || old.radius != radius;
}
