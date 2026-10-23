import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/landing/presentation/widgets/welcome_kit.dart';

const _doodleIcons = <IconData>[
  Icons.menu_book_outlined,
  Icons.gavel_rounded,
  Icons.local_library_outlined,
  Icons.bookmark_border_rounded,
  Icons.auto_stories_outlined,
  Icons.star_border_rounded,
  Icons.storefront_outlined,
  Icons.inventory_2_outlined,
];

/// Cảnh 7 — "Marketplace for Creativity": tiêu đề + nút, dải 4 tab bìa; tab chạy xong thì trượt lên,
/// một thanh "dock" biểu tượng hiện giữa màn hình, khối cam lớn trồi lên từ đáy rồi thu lại thành thẻ trung tâm
/// của một lưới bìa (video 29–35 s).
class MarketScene extends StatelessWidget {
  const MarketScene({super.key, required this.info, required this.onJoin});

  final ScrollInfo info;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = info.u;
    final compact = info.compact;
    final vw = info.vw, vh = info.vh;
    final p = info.pin;

    final headOut = seg(p, 0.3, 0.42, Curves.easeInCubic);
    final tabs = [
      l10n.wlTabClassic,
      l10n.wlTabModern,
      l10n.wlTabAbstract,
      l10n.wlTabRare,
    ];
    const tabCovers = [0, 5, 9, 27];
    final active = (seg(p, 0.12, 0.36) * 3.999).floor().clamp(0, 3);
    final tabW = compact ? vw * 0.3 : vw * 0.16;

    final heading = Positioned(
      left: vw * 0.08,
      right: vw * 0.08,
      top: vh * 0.09 - headOut * vh * 0.3,
      child: Opacity(
        opacity: 1 - headOut,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WordReveal(
                words: l10n.wlMarketTitle.split(' '),
                t: seg(p, 0.0, 0.14),
                style: landingHeadline((compact ? 30 : 60) * (compact ? 1 : u)),
              ),
            ),
            if (!compact)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: LandingButton(
                  l10n.wlMarketCta,
                  onTap: onJoin,
                  color: LandingPalette.pink,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );

    final strip = <Widget>[
      for (var i = 0; i < 4; i++)
        Positioned(
          left: vw * 0.08 + i * (tabW + 14 * u),
          top:
              lerpD(
                vh * 1.0,
                vh * (compact ? 0.4 : 0.42),
                seg(p, 0.06 + i * 0.03, 0.26 + i * 0.03, Curves.easeOutCubic),
              ) -
              headOut * vh * 0.5,
          child: Opacity(
            opacity: (1 - headOut).clamp(0.0, 1.0),
            child: SizedBox(
              width: tabW,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: i == active ? 1 : 0.55,
                    child: LandingCard(
                      asset: cover(tabCovers[i]),
                      width: tabW,
                      ratio: 1.0,
                      radius: 16 * u + 2,
                      border: 0,
                      shadow: i == active,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tabs[i],
                    style: landingText(
                      13,
                      color: i == active
                          ? LandingPalette.ink
                          : LandingPalette.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    width: i == active ? tabW : 0,
                    color: LandingPalette.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
    ];

    // dock
    final dockIn =
        seg(p, 0.38, 0.5, Curves.easeOutBack) * (1 - seg(p, 0.66, 0.74));
    const dockColors = [
      LandingPalette.orange,
      LandingPalette.pink,
      LandingPalette.blue,
      LandingPalette.green,
      LandingPalette.ink,
      LandingPalette.orange,
      LandingPalette.blue,
    ];
    final dock = Positioned(
      top: vh * 0.16,
      left: 0,
      right: 0,
      child: Center(
        child: Transform.scale(
          scale: dockIn,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LandingPalette.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(
                  color: LandingPalette.shadow,
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < (compact ? 4 : 7); i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 38 * u + 6,
                    height: 38 * u + 6,
                    decoration: BoxDecoration(
                      color: dockColors[i],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _doodleIcons[i],
                      color: LandingPalette.white,
                      size: 18 * u + 4,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // lưới + khối cam
    final cols = compact ? 3 : 5, rows = compact ? 4 : 3;
    final gap = 14 * u;
    final tw = compact ? vw * 0.2 : math.min(vw * 0.11, vh * 0.15);
    final th = tw * 1.5;
    final gridW = cols * tw + (cols - 1) * gap;
    final gridH = rows * th + (rows - 1) * gap;
    final gx0 = (vw - gridW) / 2, gy0 = (vh - gridH) / 2;
    final centerIdx = (rows ~/ 2) * cols + cols ~/ 2;
    final cx = gx0 + (centerIdx % cols) * (tw + gap);
    final cy = gy0 + (centerIdx ~/ cols) * (th + gap);

    final rise = seg(p, 0.42, 0.66, Curves.easeInOutCubic);
    final morph = seg(p, 0.76, 0.98, Curves.easeInOutCubic);
    final bw0 = lerpD(vw * 0.5, vw * (compact ? 0.84 : 0.76), rise);
    final bh0 = vh * (compact ? 0.4 : 0.52);
    final bx0 = (vw - bw0) / 2;
    final by0 = lerpD(vh * 1.05, vh * 0.3, rise);
    final bx = lerpD(bx0, cx, morph), by = lerpD(by0, cy, morph);
    final bw = lerpD(bw0, tw, morph), bh = lerpD(bh0, th, morph);
    final orange = Positioned(
      left: bx,
      top: by,
      width: bw,
      height: bh,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          lerpD(36 * u + 4, 16 * u + 2, morph),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(color: LandingPalette.orange),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, bh * 0.1),
                child: Image.asset(
                  cover(2),
                  height: bh * 0.82,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final tiles = <Widget>[];
    for (var i = 0; i < cols * rows; i++) {
      if (i == centerIdx) continue;
      final k = seg(
        p,
        0.8 + (i % 5) * 0.02,
        0.96 + (i % 5) * 0.01,
        Curves.easeOutBack,
      );
      tiles.add(
        Positioned(
          left: gx0 + (i % cols) * (tw + gap),
          top: gy0 + (i ~/ cols) * (th + gap),
          child: Opacity(
            opacity: k.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.6 + 0.4 * k,
              child: LandingCard(
                asset: cover(i * 2 + 1),
                width: tw,
                ratio: 1.18,
                radius: 16 * u + 2,
                border: 0,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: [heading, ...strip, dock, ...tiles, orange]);
  }
}

/// Cảnh 8 — "Membership": ba thẻ phí (giữa là thẻ cam nổi bật) trồi lên, rồi băng vàng chanh cuốn chữ lớn
/// chạy ngang trồi lên từ đáy kèm doodle (video 35–38 s).
class PricingScene extends StatelessWidget {
  const PricingScene({super.key, required this.info, required this.clock});

  final ScrollInfo info;
  final Animation<double> clock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = info.u;
    final compact = info.compact;
    final vw = info.vw, vh = info.vh;
    final p = info.pin;

    final plans = [
      (l10n.wlPlan1Name, '5%', l10n.wlPlan1Unit),
      (l10n.wlPlan2Name, '15%', l10n.wlPlan2Unit),
      (l10n.wlPlan3Name, '10%', l10n.wlPlan3Unit),
    ];
    final cw = compact ? vw * 0.27 : vw * 0.17;
    final ch = compact ? vh * 0.3 : vh * 0.36;

    final cards = <Widget>[];
    for (var i = 0; i < 3; i++) {
      final k = seg(p, 0.12 + i * 0.1, 0.42 + i * 0.1, Curves.easeOutCubic);
      final featured = i == 1;
      final left = compact
          ? vw * 0.05 + i * (cw + 8)
          : vw * 0.47 + i * (cw + 16 * u);
      final top =
          (compact ? vh * 0.3 : vh * 0.2) +
          (featured ? -18 : 0) +
          (1 - k) * vh * 0.8;
      cards.add(
        Positioned(
          left: left,
          top: top,
          width: cw,
          height: ch + (featured ? 24 : 0),
          child: Transform.rotate(
            angle: (1 - k) * 0.05 * (i - 1),
            child: Container(
              padding: EdgeInsets.all(compact ? 10 : 18),
              decoration: BoxDecoration(
                color: featured ? LandingPalette.orange : LandingPalette.card,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: LandingPalette.shadow,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Transform.rotate(
                      angle: 0.12 * (i - 1) + 0.06,
                      child: LandingCard(
                        asset: cover(3 + i * 4),
                        width: compact ? 40 : 64 * u,
                        ratio: 1.4,
                        radius: 10,
                        border: 2,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (featured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: LandingPalette.white24,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.wlPopular,
                            style: landingText(
                              10,
                              weight: FontWeight.w700,
                              color: LandingPalette.white,
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 18),
                      const Spacer(),
                      Text(
                        plans[i].$1,
                        style: landingText(
                          compact ? 11 : 13,
                          color: featured
                              ? LandingPalette.white70
                              : LandingPalette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plans[i].$2,
                        style: landingText(
                          compact ? 34 : 56 * u + 6,
                          weight: FontWeight.w700,
                          color: featured
                              ? LandingPalette.white
                              : LandingPalette.ink,
                          spacing: -2,
                        ),
                      ),
                      Text(
                        plans[i].$3,
                        style: landingText(
                          compact ? 10 : 12,
                          weight: FontWeight.w500,
                          color: featured
                              ? LandingPalette.white70
                              : LandingPalette.text,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final bandIn = seg(p, 0.55, 0.92, Curves.easeInOutCubic);
    final bandH = vh * (compact ? 0.34 : 0.4);
    final bandTop = lerpD(vh, vh - bandH, bandIn);
    final band = Positioned(
      left: 0,
      right: 0,
      top: bandTop,
      height: bandH,
      child: Stack(
        children: [
          const Positioned.fill(child: _YellowBand()),
          Positioned.fill(
            child: _BandText(
              clock: clock,
              shift: p * vw * 0.6,
              u: u,
              compact: compact,
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        Positioned(
          left: vw * 0.08,
          top: compact ? vh * 0.1 : vh * 0.24,
          width: compact ? vw * 0.84 : vw * 0.34,
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
                      l10n.wlPriceEyebrow.toUpperCase(),
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
                words: l10n.wlPriceTitle.split(' '),
                t: seg(p, 0.0, 0.25),
                style: landingHeadline((compact ? 30 : 56) * (compact ? 1 : u)),
              ),
            ],
          ),
        ),
        ...cards,
        band,
      ],
    );
  }
}

class _YellowBand extends StatelessWidget {
  const _YellowBand();

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(color: LandingPalette.yellow);
}

/// Chữ lớn chạy ngang trên băng vàng, xen ô bìa nhỏ, và doodle nổi bên dưới.
class _BandText extends StatelessWidget {
  const _BandText({
    required this.clock,
    required this.shift,
    required this.u,
    required this.compact,
  });

  final Animation<double> clock;
  final double shift;
  final double u;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final size = (compact ? 38 : 92) * (compact ? 1.0 : u);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final phrases = [l10n.wlMarquee, l10n.wlMarquee2];
        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: box.maxHeight * 0.14,
              child: LandingMarquee(
                clock: clock,
                itemWidth: size * 13,
                gap: size * 0.4,
                height: size * 1.25,
                count: 2,
                speed: 55,
                shift: shift,
                itemBuilder: (context, i) => Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          phrases[i],
                          style: landingText(size, spacing: -size * 0.04),
                        ),
                      ),
                    ),
                    SizedBox(width: size * 0.2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(size * 0.18),
                      child: Image.asset(
                        cover(i * 4 + 3),
                        width: size * 0.7,
                        height: size * 0.9,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            for (var i = 0; i < 8; i++)
              Positioned(
                left: w * (0.06 + i * 0.115) + (i.isOdd ? 12 : 0),
                bottom: box.maxHeight * (i.isEven ? 0.08 : 0.2),
                child: Doodle(
                  icon: _doodleIcons[i],
                  clock: clock,
                  phase: i * 0.9,
                  size: 18 * u + 4,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Cảnh 9 — băng vàng (nối tiếp cảnh trước), hai thẻ lớn (hồng / trắng) trồi lên, rồi chân trang
/// "Our platform, your art" (video 38–43 s).
class OutroScene extends StatelessWidget {
  const OutroScene({
    super.key,
    required this.info,
    required this.clock,
    required this.onJoin,
    required this.onAuctions,
    required this.onEnter,
    required this.onExplore,
    required this.onConsign,
    required this.onLogin,
  });

  final ScrollInfo info;
  final Animation<double> clock;
  final VoidCallback onJoin;
  final VoidCallback onAuctions;
  final VoidCallback onEnter;
  final VoidCallback onExplore;
  final VoidCallback onConsign;
  final VoidCallback onLogin;

  /// Chiều cao cảnh (băng vàng + hai thẻ + chân trang).
  static double heightFor(double vh, bool compact) {
    final bandH = vh * (compact ? 0.3 : 0.38);
    final cardH = vh * (compact ? 0.62 : 0.72);
    return bandH + vh * 0.06 + cardH + vh * 0.08 + (compact ? 620 : 420);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = info.u;
    final compact = info.compact;
    final vw = info.vw, vh = info.vh;

    final bandH = vh * (compact ? 0.3 : 0.38);
    final cardsTop = bandH + vh * 0.06;
    final cardH = vh * (compact ? 0.62 : 0.72);
    final footTop = cardsTop + cardH + vh * 0.08;
    final cw = compact ? vw * 0.86 : vw * 0.42;

    Widget big({
      required double left,
      required double top,
      required Color bg,
      required Color fg,
      required String title,
      required String body,
      required String cta,
      required VoidCallback onTap,
      required int coverIndex,
      required bool dark,
    }) {
      final k = revealAt(info, top, span: 0.35);
      return Positioned(
        left: left,
        top: top + (1 - k) * 90,
        width: cw,
        height: cardH,
        child: Opacity(
          opacity: k,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: bg),
                Positioned(
                  right: -cw * 0.08,
                  top: cardH * 0.04,
                  child: Transform.rotate(
                    angle: dark ? 0.06 : -0.08,
                    child: LandingCard(
                      asset: cover(coverIndex),
                      width: cw * 0.52,
                      ratio: 1.45,
                      radius: 24,
                      border: 0,
                    ),
                  ),
                ),
                Positioned(
                  left: 22,
                  bottom: 22,
                  right: cw * 0.3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: landingHeadline(
                          (compact ? 24 : 34) * (compact ? 1 : u),
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body,
                        style: landingText(
                          13,
                          weight: FontWeight.w500,
                          color: fg.withValues(alpha: 0.78),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LandingButton(
                        cta,
                        onTap: onTap,
                        color: dark ? LandingPalette.white : LandingPalette.ink,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final foot = revealAt(info, footTop, span: 0.3);
    Widget link(String t, VoidCallback f) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: f,
          child: Text(
            t,
            style: landingText(
              13,
              weight: FontWeight.w500,
              color: LandingPalette.text,
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: bandH,
          child: Stack(
            children: [
              const Positioned.fill(child: _YellowBand()),
              Positioned.fill(
                child: _BandText(
                  clock: clock,
                  shift: info.local * 0.5 + vw,
                  u: u,
                  compact: compact,
                ),
              ),
            ],
          ),
        ),
        big(
          left: compact ? vw * 0.07 : vw * 0.06,
          top: cardsTop,
          bg: LandingPalette.pink,
          fg: LandingPalette.white,
          title: l10n.wlOutro1Title,
          body: l10n.wlOutro1Body,
          cta: l10n.wlOutro1Cta,
          onTap: onJoin,
          coverIndex: 4,
          dark: true,
        ),
        if (!compact)
          big(
            left: vw * 0.52,
            top: cardsTop,
            bg: LandingPalette.card,
            fg: LandingPalette.ink,
            title: l10n.wlOutro2Title,
            body: l10n.wlOutro2Body,
            cta: l10n.wlOutro2Cta,
            onTap: onAuctions,
            coverIndex: 11,
            dark: false,
          ),
        Positioned(
          left: vw * 0.03,
          right: vw * 0.03,
          top: footTop + (1 - foot) * 60,
          child: Opacity(
            opacity: foot,
            child: Container(
              padding: EdgeInsets.all(compact ? 20 : 36),
              decoration: BoxDecoration(
                color: LandingPalette.panel,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _flex(
                    compact: compact,
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.wlFooterTitle,
                          style: landingHeadline(
                            (compact ? 26 : 38) * (compact ? 1 : u),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 380,
                          child: Text(
                            l10n.wlFooterBody,
                            style: landingText(
                              13,
                              weight: FontWeight.w500,
                              color: LandingPalette.text,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        LandingButton(l10n.wlEnter, onTap: onEnter, size: 14),
                      ],
                    ),
                  ),
                  SizedBox(width: 40, height: compact ? 24 : 0),
                  _flex(
                    compact: compact,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.wlFooterProduct,
                          style: landingText(13, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        link(l10n.wlNavDiscover, onExplore),
                        link(l10n.navAuctions, onAuctions),
                        link(l10n.consignTitle, onConsign),
                      ],
                    ),
                  ),
                  SizedBox(width: 40, height: compact ? 12 : 0),
                  _flex(
                    compact: compact,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.wlFooterAccount,
                          style: landingText(13, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        link(l10n.login, onLogin),
                        link(l10n.wlEnter, onEnter),
                        const SizedBox(height: 16),
                        Text(
                          l10n.wlCopyright,
                          style: landingText(
                            11,
                            weight: FontWeight.w500,
                            color: LandingPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Trên điện thoại các cột chân trang xếp dọc trong chiều cao không giới hạn → không dùng Flexible.
Widget _flex({required bool compact, int flex = 1, required Widget child}) =>
    compact ? child : Flexible(flex: flex, child: child);
