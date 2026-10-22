import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/landing/presentation/widgets/welcome_kit.dart';

/// Cảnh 4 — đoạn văn lớn hiện từng từ khi cuộn; rồi chồng thẻ rơi xuống đè lên chữ, tách thành
/// hàng chéo kèm thẻ chữ, cuối cùng xếp thành lưới 3×2 trong khung có tab đen; tiêu đề "tầm nhìn" hiện bên trái
/// cùng các doodle nổi (video 13–20 s).
class StoryScene extends StatelessWidget {
  const StoryScene({super.key, required this.info, required this.clock});

  final ScrollInfo info;
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = info.u;
    final compact = info.compact;
    final vw = info.vw, vh = info.vh;
    final p = info.pin;

    final paraOpacity = 1 - seg(p, 0.5, 0.62);
    final para = Positioned(
      left: vw * 0.12,
      right: vw * 0.12,
      top: vh * 0.3,
      child: Opacity(
        opacity: paraOpacity,
        child: WordReveal(
          words: l10n.wlStory.split(' '),
          t: seg(p, 0.0, 0.36),
          align: TextAlign.center,
          style: landingText(
            (compact ? 21 : 44) * (compact ? 1 : u),
            weight: FontWeight.w600,
            spacing: -1,
            height: 1.18,
          ),
        ),
      ),
    );

    // ── chồng thẻ: rơi → hàng chéo → lưới ──
    const n = 6;
    final cw = (compact ? 92 : 150) * (compact ? 1.0 : u);
    final gw = compact ? vw * 0.27 : vw * 0.115;
    final cards = <Widget>[];
    const covers = [2, 8, 4, 12, 6, 1];
    for (var j = 0; j < n; j++) {
      final dir = j.isEven ? 1.0 : -1.0;
      final drop = seg(
        p,
        0.30 + j * 0.022,
        0.46 + j * 0.022,
        Curves.easeOutBack,
      );
      final s1 = seg(p, 0.52, 0.74, Curves.easeInOutCubic);
      final s2 = seg(p, 0.77, 0.98, Curves.easeInOutCubic);

      // vị trí chồng
      final sx = vw / 2 - cw / 2 + (j - 2.5) * 3;
      final sy = vh * 0.40 + (j - 2.5) * 2;
      final srot = dir * 0.05 * (j / 5 + 0.4);
      // hàng chéo
      final dx = compact
          ? vw * 0.08 + j * vw * 0.13
          : vw * 0.30 + j * vw * 0.085;
      final dy = compact
          ? vh * 0.5 + j * vh * 0.035
          : vh * 0.30 + j * vh * 0.062;
      // lưới
      final col = j % 3, row = j ~/ 3;
      final gh = gw * 1.28;
      final gx = (compact ? vw * 0.08 : vw * 0.555) + col * (gw + 12 * u);
      final gy = (compact ? vh * 0.46 : vh * 0.36) + row * (gh + 12 * u);

      var x = lerpD(sx, dx, s1);
      var y = lerpD(sy, dy, s1);
      var rot = lerpD(srot, -0.07, s1);
      var w = lerpD(cw, cw, s1);
      var ratio = lerpD(1.45, 1.2, s1);
      x = lerpD(x, gx, s2);
      y = lerpD(y, gy, s2);
      rot = lerpD(rot, 0, s2);
      w = lerpD(w, gw, s2);
      ratio = lerpD(ratio, 1.28, s2);
      y += (1 - drop) * -vh * 1.1;
      rot += (1 - drop) * dir * 0.9;

      cards.add(
        Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: seg(p, 0.28 + j * 0.022, 0.34 + j * 0.022),
            child: Transform.rotate(
              angle: rot,
              child: LandingCard(
                asset: cover(covers[j]),
                width: w,
                ratio: ratio,
                radius: 14 * u + 2,
              ),
            ),
          ),
        ),
      );
    }

    // thẻ chữ bên trái hàng chéo
    final labelIn =
        seg(p, 0.6, 0.76, Curves.easeOutCubic) * (1 - seg(p, 0.78, 0.9));
    final label = Positioned(
      left: vw * 0.09,
      top: vh * 0.3,
      child: Opacity(
        opacity: labelIn,
        child: Transform.translate(
          offset: Offset(0, (1 - labelIn) * 30),
          child: Container(
            width: (compact ? 150 : 210) * (compact ? 1 : u),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LandingPalette.card,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: LandingPalette.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.wlDeckLabel.toUpperCase(),
                  style: landingText(11, weight: FontWeight.w800, spacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.wlDeckTitle,
                  style: landingText(
                    15,
                    weight: FontWeight.w700,
                    spacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.wlDeckBody,
                  style: landingText(
                    11.5,
                    weight: FontWeight.w500,
                    color: LandingPalette.text,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // khung có tab đen phía sau lưới + tiêu đề tầm nhìn
    final frameIn = seg(p, 0.74, 0.88, Curves.easeOut);
    final frameLeft = compact ? vw * 0.05 : vw * 0.535;
    final frame = Positioned(
      left: frameLeft,
      top: (compact ? vh * 0.46 : vh * 0.36) - 46,
      child: Opacity(
        opacity: frameIn,
        child: Container(
          width: 3 * gw + 2 * 12 * u + (compact ? vw * 0.05 : vw * 0.04),
          height: 2 * gw * 1.28 + 12 * u + 78,
          decoration: BoxDecoration(
            color: LandingPalette.card,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: LandingPalette.shadow,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 40,
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: LandingPalette.ink,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Text(
                    l10n.wlTabTrade,
                    style: landingText(13, color: LandingPalette.white),
                  ),
                  const Spacer(),
                  Text(
                    l10n.wlTabMine,
                    style: landingText(13, color: LandingPalette.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final vision = Positioned(
      left: vw * 0.08,
      top: compact ? vh * 0.12 : vh * 0.28,
      width: compact ? vw * 0.84 : vw * 0.38,
      child: Opacity(
        opacity: seg(p, 0.84, 0.95),
        child: Transform.translate(
          offset: Offset(0, (1 - seg(p, 0.84, 0.95)) * 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.wlVisionTitle,
                style: landingHeadline((compact ? 28 : 48) * (compact ? 1 : u)),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.wlVisionBody,
                style: landingText(
                  compact ? 13 : 15,
                  weight: FontWeight.w500,
                  color: LandingPalette.text,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final icons = [
      Icons.menu_book_outlined,
      Icons.gavel_rounded,
      Icons.local_library_outlined,
      Icons.bookmark_border_rounded,
      Icons.auto_stories_outlined,
      Icons.star_border_rounded,
    ];
    final doodles = <Widget>[
      for (var i = 0; i < icons.length; i++)
        Positioned(
          left: vw * 0.08 + (i % 3) * 64 * u + (i ~/ 3) * 30,
          top: vh * (compact ? 0.3 : 0.62) + (i ~/ 3) * 70 * u,
          child: Opacity(
            opacity: seg(p, 0.82 + i * 0.02, 0.9 + i * 0.02),
            child: Doodle(
              icon: icons[i],
              clock: clock,
              phase: i * 1.3,
              size: 20 * u + 4,
            ),
          ),
        ),
    ];

    return Stack(children: [para, frame, label, vision, ...doodles, ...cards]);
  }
}

/// Cảnh 5 — "You will find yourself among us": hai hàng ô bìa nghiêng nghiêng trôi ngược chiều
/// theo độ cuộn, tiêu đề ở giữa hiện từng từ (video 21–23 s).
class AmongScene extends StatelessWidget {
  const AmongScene({super.key, required this.info});

  final ScrollInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = info.u;
    final compact = info.compact;
    final vw = info.vw, vh = info.vh;
    final p = info.pin;

    final tile = (compact ? 54 : 76) * (compact ? 1.0 : u);
    final step = tile * 1.35;
    final pop = seg(p, 0.0, 0.25, Curves.easeOutBack);
    Widget row({
      required double top,
      required bool reverse,
      required int offset,
    }) {
      final shift = p * vw * 0.7 * (reverse ? -1 : 1);
      return Positioned(
        left: 0,
        right: 0,
        top: top,
        height: tile * 1.5,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < 40; i++)
              Positioned(
                left: i * step - (reverse ? step * 22 : step * 4) + shift,
                top: math.sin(i * 1.7 + offset) * tile * 0.22 + tile * 0.2,
                child: Transform.scale(
                  scale: pop,
                  child: Transform.rotate(
                    angle: math.sin(i * 2.3 + offset) * 0.16,
                    child: LandingCard(
                      asset: cover(i * 3 + offset),
                      width: tile,
                      ratio: 1.0,
                      radius: 16 * u + 2,
                      border: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        row(top: vh * (compact ? 0.18 : 0.07), reverse: false, offset: 0),
        row(top: vh * (compact ? 0.64 : 0.68), reverse: true, offset: 7),
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: vw * 0.14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WordReveal(
                  words: l10n.wlAmongTitle.split(' '),
                  t: seg(p, 0.05, 0.5),
                  align: TextAlign.center,
                  style: landingHeadline(
                    (compact ? 32 : 64) * (compact ? 1 : u),
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: seg(p, 0.35, 0.6),
                  child: Text(
                    l10n.wlAmongSub,
                    textAlign: TextAlign.center,
                    style: landingText(
                      compact ? 13 : 16,
                      weight: FontWeight.w500,
                      color: LandingPalette.text,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Cảnh 6 — "Every piece of art tells a story": nhãn + tiêu đề, ba thẻ tính năng (trắng / xanh / đen)
/// trồi lên lần lượt rồi trượt sang trái khi cuộn tiếp (video 24–28 s).
class FeaturesScene extends StatelessWidget {
  const FeaturesScene({super.key, required this.info});

  final ScrollInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = info.u;
    final compact = info.compact;
    final vw = info.vw, vh = info.vh;
    final p = info.pin;

    final cardW = compact ? vw * 0.74 : vw * 0.27;
    final cardH = compact ? vh * 0.5 : vh * 0.5;
    final slide =
        seg(p, 0.6, 1.0, Curves.easeInOutCubic) *
        (compact ? cardW * 1.2 : vw * 0.12);

    Widget card(
      int i, {
      required Color bg,
      required Color fg,
      required String title,
      required String body,
      required Widget art,
    }) {
      final k = seg(p, 0.12 + i * 0.12, 0.45 + i * 0.12, Curves.easeOutCubic);
      return Positioned(
        left: vw * 0.08 + i * (cardW + 18 * u) - slide,
        top: lerpD(vh * 1.05, vh * (compact ? 0.38 : 0.36), k),
        width: cardW,
        height: cardH,
        child: Transform.rotate(
          angle: (1 - k) * 0.06 * (i.isEven ? 1 : -1),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: LandingPalette.shadow,
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: art,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: landingText(
                    compact ? 17 : 20 * u + 2,
                    weight: FontWeight.w700,
                    color: fg,
                    spacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: landingText(
                    13,
                    weight: FontWeight.w500,
                    color: fg.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: vw * 0.08,
          right: vw * 0.08,
          top: vh * (compact ? 0.1 : 0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: seg(p, 0.0, 0.1),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: LandingPalette.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.wlFeatEyebrow.toUpperCase(),
                      style: landingText(
                        12,
                        weight: FontWeight.w700,
                        color: LandingPalette.text,
                        spacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              WordReveal(
                words: l10n.wlFeatTitle.split(' '),
                t: seg(p, 0.0, 0.3),
                style: landingHeadline((compact ? 30 : 58) * (compact ? 1 : u)),
              ),
            ],
          ),
        ),
        card(
          0,
          bg: LandingPalette.card,
          fg: LandingPalette.ink,
          title: l10n.wlFeat1Title,
          body: l10n.wlFeat1Body,
          art: Image.asset(
            cover(14),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        card(
          1,
          bg: LandingPalette.blue,
          fg: LandingPalette.white,
          title: l10n.wlFeat2Title,
          body: l10n.wlFeat2Body,
          art: DecoratedBox(
            decoration: const BoxDecoration(color: LandingPalette.blueSoft),
            child: Center(
              child: Transform.rotate(
                angle: -0.1,
                child: LandingCard(
                  asset: cover(5),
                  width: cardW * 0.42,
                  ratio: 1.45,
                  radius: 18,
                ),
              ),
            ),
          ),
        ),
        card(
          2,
          bg: LandingPalette.ink,
          fg: LandingPalette.white,
          title: l10n.wlFeat3Title,
          body: l10n.wlFeat3Body,
          art: DecoratedBox(
            decoration: const BoxDecoration(color: LandingPalette.darkPanel),
            child: Center(
              child: Container(
                width: cardW * 0.4,
                decoration: BoxDecoration(
                  color: LandingPalette.black,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: LandingPalette.white24, width: 2),
                ),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    cover(27),
                    fit: BoxFit.cover,
                    height: cardH * 0.52,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
