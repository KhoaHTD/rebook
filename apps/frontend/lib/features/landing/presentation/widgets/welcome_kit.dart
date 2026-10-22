import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Bìa sách dùng trên trang giới thiệu — ảnh đóng gói trong `assets/books/`, xếp theo độ rực rỡ để các quạt bìa nhìn vui mắt.
const kLandingCovers = <String>[
  'assets/books/so-do-0.jpg',
  'assets/books/tat-den-0.jpg',
  'assets/books/sapiens-1.jpg',
  'assets/books/truyen-kieu-1.jpg',
  'assets/books/bi-vo-1.jpg',
  'assets/books/vang-bong-2.jpg',
  'assets/books/rung-na-uy-1.jpg',
  'assets/books/de-men-0.jpg',
  'assets/books/clean-code-1.jpg',
  'assets/books/nam-phong-1.jpg',
  'assets/books/tho-tho-2.jpg',
  'assets/books/leu-chong-1.jpg',
  'assets/books/dac-nhan-tam-0.jpg',
  'assets/books/nha-gia-kim-0.jpg',
  'assets/books/giao-trinh-ctdl-0.jpg',
  'assets/books/so-do-1.jpg',
  'assets/books/tat-den-1.jpg',
  'assets/books/sapiens-0.jpg',
  'assets/books/truyen-kieu-0.jpg',
  'assets/books/bi-vo-0.jpg',
  'assets/books/vang-bong-0.jpg',
  'assets/books/rung-na-uy-0.jpg',
  'assets/books/de-men-1.jpg',
  'assets/books/clean-code-0.jpg',
  'assets/books/nam-phong-0.jpg',
  'assets/books/tho-tho-0.jpg',
  'assets/books/leu-chong-0.jpg',
  'assets/books/tu-dien-0.jpg',
];

String cover(int i) => kLandingCovers[i % kLandingCovers.length];

/// Số đo của trang ở thời điểm cuộn hiện tại, tính cho một cảnh bắt đầu tại [start] cao [height].
class ScrollInfo {
  const ScrollInfo({
    required this.offset,
    required this.vh,
    required this.vw,
    required this.start,
    required this.height,
  });

  final double offset;
  final double vh;
  final double vw;
  final double start;
  final double height;

  bool get compact => vw < 700;

  /// Hệ số co giãn kích thước theo bề rộng (thiết kế gốc 1440px).
  double get u =>
      compact ? (vw / 560).clamp(0.5, 1.0) : (vw / 1440).clamp(0.55, 1.2);

  double get local => offset - start;

  /// 0 khi đỉnh cảnh chạm đáy màn hình → 1 khi đỉnh cảnh chạm đỉnh màn hình.
  double get enter => ((offset + vh - start) / vh).clamp(0.0, 1.0);

  /// Tiến độ của cảnh được ghim (pinned): 0 → 1 trong lúc cảnh đứng yên và cuộn qua.
  double get pin =>
      height <= vh ? 0.0 : (local / (height - vh)).clamp(0.0, 1.0);
}

/// Phần của [p] trong đoạn [a, b], 0..1, có thể áp đường cong.
double seg(double p, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((p - a) / (b - a)).clamp(0.0, 1.0));

double lerpD(double a, double b, double t) => a + (b - a) * t;

/// Một cảnh của trang cuộn. Cảnh [pinned] giữ nội dung đứng yên (cao đúng một màn hình)
/// trong lúc người dùng cuộn qua [height]; [builder] nhận [ScrollInfo] để vẽ theo tiến độ cuộn.
/// Cảnh nằm ngoài màn hình không được vẽ (giữ nguyên chiều cao) để cuộn mượt.
class WelcomeScene extends StatelessWidget {
  const WelcomeScene({
    super.key,
    required this.controller,
    required this.start,
    required this.height,
    required this.builder,
    this.pinned = false,
    this.extra,
  });

  final ScrollController controller;
  final double start;
  final double height;
  final bool pinned;
  final Widget Function(BuildContext context, ScrollInfo info) builder;

  /// Animation phụ (đồng hồ, intro…) cần vẽ lại cảnh theo.
  final Listenable? extra;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([controller, ?extra]),
      builder: (context, _) {
        final off = controller.hasClients
            ? controller.offset
            : controller.initialScrollOffset;
        final visible =
            off + size.height * 1.3 > start &&
            off < start + height + size.height * 0.3;
        if (!visible) return SizedBox(height: height);
        final info = ScrollInfo(
          offset: off,
          vh: size.height,
          vw: size.width,
          start: start,
          height: height,
        );
        final content = builder(context, info);
        if (!pinned) return SizedBox(height: height, child: content);
        final dy = info.local.clamp(0.0, height - size.height);
        return SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned(
                top: dy,
                left: 0,
                right: 0,
                height: size.height,
                child: ClipRect(child: content),
              ),
            ],
          ),
        );
      },
    );
  }
}

TextStyle landingText(
  double size, {
  FontWeight weight = FontWeight.w600,
  Color color = LandingPalette.ink,
  double spacing = 0,
  double height = 1.1,
}) => TextStyle(
  fontFamily: AppFonts.family,
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: spacing,
  height: height,
);

/// Tiêu đề lớn của trang giới thiệu (chữ đậm, khít, giống video).
TextStyle landingHeadline(double size, {Color color = LandingPalette.ink}) =>
    landingText(
      size,
      weight: FontWeight.w600,
      color: color,
      spacing: -size * 0.035,
      height: 1.05,
    );

/// Thẻ bìa sách: viền trắng dày, bo góc, bóng mềm — các "thẻ tác phẩm" của video.
class LandingCard extends StatelessWidget {
  const LandingCard({
    super.key,
    required this.asset,
    required this.width,
    this.ratio = 1.4,
    this.radius = 14,
    this.border = 3,
    this.shadow = true,
  });

  final String asset;
  final double width;
  final double ratio;
  final double radius;
  final double border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width * ratio,
      padding: EdgeInsets.all(border),
      decoration: BoxDecoration(
        color: LandingPalette.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: LandingPalette.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((radius - border).clamp(2.0, 99.0)),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          width: width,
          height: width * ratio,
        ),
      ),
    );
  }
}

/// Nhãn nổi hình bong bóng ("@gacxep") dán lên thẻ, hơi nghiêng.
class StickerChip extends StatelessWidget {
  const StickerChip(
    this.text, {
    super.key,
    this.color = LandingPalette.blue,
    this.size = 14,
    this.angle = 0,
  });

  final String text;
  final Color color;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: size * 0.8,
          vertical: size * 0.42,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size),
            topRight: Radius.circular(size),
            bottomRight: Radius.circular(size),
            bottomLeft: Radius.circular(size * 0.25),
          ),
        ),
        child: Text(
          text,
          style: landingText(
            size,
            weight: FontWeight.w600,
            color: LandingPalette.white,
          ),
        ),
      ),
    );
  }
}

/// Nút viên thuốc của trang giới thiệu: đen (chính) hoặc trong suốt (phụ).
class LandingButton extends StatelessWidget {
  const LandingButton(
    this.label, {
    super.key,
    required this.onTap,
    this.primary = true,
    this.size = 15,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size * 1.4,
            vertical: size * 0.72,
          ),
          decoration: ShapeDecoration(
            shape: const StadiumBorder(),
            color: primary ? (color ?? LandingPalette.ink) : Colors.transparent,
          ),
          child: Text(
            label,
            style: landingText(
              size,
              color: primary ? LandingPalette.white : LandingPalette.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Băng chuyền chạy ngang vô tận. [shift] cộng thêm dịch chuyển theo cuộn; [clock] là giây.
class LandingMarquee extends StatelessWidget {
  const LandingMarquee({
    super.key,
    required this.clock,
    required this.itemWidth,
    required this.gap,
    required this.height,
    required this.itemBuilder,
    required this.count,
    this.speed = 40,
    this.reverse = false,
    this.shift = 0,
  });

  final Animation<double> clock;
  final double itemWidth;
  final double gap;
  final double height;
  final int count;
  final Widget Function(BuildContext, int) itemBuilder;
  final double speed;
  final bool reverse;
  final double shift;

  @override
  Widget build(BuildContext context) {
    final loop = (itemWidth + gap) * count;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final repeats = (box.maxWidth / loop).ceil() + 2;
          return ClipRect(
            child: AnimatedBuilder(
              animation: clock,
              builder: (context, _) {
                final d = (clock.value * 3600 * speed + shift) % loop;
                final dx = reverse ? d - loop : -d;
                return OverflowBox(
                  alignment: Alignment.centerLeft,
                  maxWidth: loop * repeats,
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: Row(
                      children: [
                        for (var r = 0; r < repeats; r++)
                          for (var i = 0; i < count; i++)
                            Padding(
                              padding: EdgeInsets.only(right: gap),
                              child: SizedBox(
                                width: itemWidth,
                                height: height,
                                child: itemBuilder(context, i),
                              ),
                            ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Dòng chữ có từng từ hiện dần (xám → đen) theo tiến độ [t] 0..1, kèm [inline] widget chèn giữa câu.
class WordReveal extends StatelessWidget {
  const WordReveal({
    super.key,
    required this.words,
    required this.t,
    required this.style,
    this.align = TextAlign.left,
    this.accent,
    this.accentFrom = -1,
    this.accentTo = -1,
  });

  final List<String> words;
  final double t;
  final TextStyle style;
  final TextAlign align;
  final Color? accent;

  /// Các từ có chỉ số trong [accentFrom, accentTo) được tô màu [accent].
  final int accentFrom;
  final int accentTo;

  @override
  Widget build(BuildContext context) {
    final n = words.length;
    final spans = <InlineSpan>[];
    for (var i = 0; i < n; i++) {
      final k = seg(t, i / n * 0.82, i / n * 0.82 + 0.18);
      final isAccent = accent != null && i >= accentFrom && i < accentTo;
      final target = isAccent ? accent! : (style.color ?? LandingPalette.ink);
      spans.add(
        TextSpan(
          text: i == n - 1 ? words[i] : '${words[i]} ',
          style: TextStyle(color: Color.lerp(LandingPalette.muted, target, k)),
        ),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      textAlign: align,
      style: style,
    );
  }
}

/// Biểu tượng nguệch ngoạc nổi lơ lửng (sách, búa, kệ…) — các "doodle" của video.
class Doodle extends StatelessWidget {
  const Doodle({
    super.key,
    required this.icon,
    required this.clock,
    required this.phase,
    this.size = 26,
    this.color = LandingPalette.ink,
  });

  final IconData icon;
  final Animation<double> clock;
  final double phase;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final s = clock.value * 3600;
        return Transform.translate(
          offset: Offset(
            math.sin(s * 0.9 + phase) * 6,
            math.cos(s * 0.7 + phase * 1.7) * 7,
          ),
          child: Transform.rotate(
            angle: math.sin(s * 0.6 + phase) * 0.25,
            child: Container(
              width: size * 1.9,
              height: size * 1.9,
              decoration: BoxDecoration(
                color: LandingPalette.white,
                shape: BoxShape.circle,
                border: Border.all(color: LandingPalette.ink, width: 1.4),
              ),
              child: Icon(icon, size: size, color: color),
            ),
          ),
        );
      },
    );
  }
}

/// Tiến độ "hiện ra" của một phần tử nằm ở [yInScene] (tính từ đỉnh cảnh) khi nó đi vào 90% chiều cao màn hình.
double revealAt(
  ScrollInfo info,
  double yInScene, {
  double span = 0.3,
  Curve curve = Curves.easeOutCubic,
}) {
  final top =
      info.start + yInScene - info.offset; // vị trí đỉnh phần tử trên màn hình
  return curve.transform(
    ((info.vh * 0.9 - top) / (info.vh * span)).clamp(0.0, 1.0),
  );
}
