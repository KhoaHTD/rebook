import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/l10n/l10n.dart';
import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/features/landing/presentation/widgets/welcome_kit.dart';

/// Cảnh 1 — Hero. Đoạn mở đầu chạy theo thời gian ([intro] 0..1, ~4s):
/// một thẻ bìa lộn nhào từ dưới lên giữa màn hình, tiêu đề hiện từng từ (xám → đen),
/// 6 thẻ còn lại toé ra thành quạt, chip nổi bật lên, rồi dòng mô tả + nút.
/// Khi cuộn (cảnh được ghim), quạt thu lại về một thẻ ở giữa và chữ mờ đi (video 3,5–4,5 s).
class HeroScene extends StatelessWidget {
  const HeroScene({
    super.key,
    required this.info,
    required this.intro,
    required this.onExplore,
    required this.onAuctions,
  });

  final ScrollInfo info;
  final Animation<double> intro;
  final VoidCallback onExplore;
  final VoidCallback onAuctions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = info.u;
    final compact = info.compact;
    final t = intro.value;
    final exit = seg(info.pin, 0.0, 0.8, Curves.easeInOutCubic);
    final vw = info.vw, vh = info.vh;

    final words = l10n.wlHeroTitle.split(' ');
    final headSize = (compact ? 40 : 78) * (compact ? 1.0 : u);
    final headline = Opacity(
      opacity: (1 - exit * 1.6).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, -exit * 40),
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < words.length; i++)
              () {
                final k = seg(
                  t,
                  0.05 + i * 0.05,
                  0.05 + i * 0.05 + 0.13,
                  Curves.easeOut,
                );
                return Transform.translate(
                  offset: Offset(0, (1 - k) * 22),
                  child: Text(
                    '${words[i]} ',
                    style: landingHeadline(headSize).copyWith(
                      color: Color.lerp(
                        LandingPalette.muted,
                        LandingPalette.ink,
                        k,
                      ),
                    ),
                  ),
                );
              }(),
          ],
        ),
      ),
    );

    // ── quạt bìa ──
    final cw = (compact ? 96 : 156) * (compact ? 1.0 : u);
    final ch = cw * 1.45;
    final spacing = cw * (compact ? 0.62 : 0.74);
    final cy = vh * (compact ? 0.5 : 0.575) + exit * vh * 0.1;
    final rise = seg(t, 0.0, 0.30, Curves.easeOutCubic);
    final cards = <Widget>[];
    final order = [-3, 3, -2, 2, -1, 1, 0];
    for (final k in order) {
      final f = k == 0
          ? 1.0
          : seg(
              t,
              0.30 + 0.03 * k.abs(),
              0.66 + 0.03 * k.abs(),
              Curves.easeOutBack,
            );
      final x = lerpD(0, k * spacing, f) * (1 - exit);
      var y = lerpD(0, k * k * 7.0 * u, f) * (1 - exit);
      var rot = lerpD(0, k * 0.075, f) * (1 - exit * 0.7);
      var opacity = k == 0 ? 1.0 : seg(f, 0, 0.3);
      final scale = 1 - exit * 0.32;
      if (k == 0) {
        y += (1 - rise) * vh * 0.55;
        rot += (1 - rise) * 0.9;
      }
      if (exit > 0.85) opacity *= (1 - seg(exit, 0.85, 1.0) * (k == 0 ? 0 : 1));
      final tumble = k == 0 ? (1 - rise) * 1.25 : 0.0;
      cards.add(
        Positioned(
          left: vw / 2 - cw / 2 + x,
          top: cy - ch / 2 + y,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(tumble)
                ..rotateZ(rot)
                ..scaleByDouble(scale, scale, 1, 1),
              child: LandingCard(
                asset: cover([3, 0, 1, 2, 4, 5, 6][k + 3]),
                width: cw,
                ratio: 1.45,
                radius: 14 * u + 2,
              ),
            ),
          ),
        ),
      );
    }

    final chipPop = seg(t, 0.64, 0.82, Curves.easeOutBack);
    final chips = [
      Positioned(
        left: vw / 2 - spacing * 3.5 - cw * 0.2,
        top: cy - ch * 0.62,
        child: Transform.scale(
          scale: chipPop * (1 - exit),
          child: StickerChip(
            l10n.wlChipShop,
            size: (compact ? 11 : 15) * (compact ? 1 : u),
            angle: -0.05,
          ),
        ),
      ),
      Positioned(
        left: vw / 2 + spacing * 3.1,
        top: cy - ch * 0.68,
        child: Transform.scale(
          scale: chipPop * (1 - exit),
          child: StickerChip(
            l10n.wlChipLive,
            color: LandingPalette.green,
            size: (compact ? 11 : 15) * (compact ? 1 : u),
            angle: 0.06,
          ),
        ),
      ),
    ];

    final subOpacity = seg(t, 0.70, 0.90) * (1 - exit * 2).clamp(0.0, 1.0);
    final ctaOpacity = seg(t, 0.78, 1.0) * (1 - exit * 2).clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned(
          top: vh * (compact ? 0.16 : 0.12),
          left: vw * 0.1,
          right: vw * 0.1,
          child: headline,
        ),
        ...cards,
        ...chips,
        Positioned(
          top: cy + ch / 2 + 62 * u,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Opacity(
                opacity: subOpacity,
                child: Transform.translate(
                  offset: Offset(0, (1 - subOpacity) * 14),
                  child: SizedBox(
                    width: math.min(vw * 0.8, 460),
                    child: Text(
                      l10n.wlHeroSub,
                      textAlign: TextAlign.center,
                      style: landingText(
                        compact ? 13 : 15 * u + 1,
                        weight: FontWeight.w500,
                        color: LandingPalette.text,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18 * u),
              Opacity(
                opacity: ctaOpacity,
                child: Transform.translate(
                  offset: Offset(0, (1 - ctaOpacity) * 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LandingButton(
                        l10n.wlHeroCta,
                        onTap: onExplore,
                        size: compact ? 13 : 15,
                      ),
                      const SizedBox(width: 8),
                      LandingButton(
                        l10n.wlHeroCta2,
                        onTap: onAuctions,
                        primary: false,
                        size: compact ? 13 : 15,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cảnh 2 — "Showcase, Sell & acquire": nhãn nhỏ, tiêu đề có từ nhấn đỏ hiện dần,
/// chồng thẻ chéo trượt vào từ bên phải (video 5–7 s).
class ShowcaseScene extends StatelessWidget {
  const ShowcaseScene({
    super.key,
    required this.info,
    required this.onStart,
    required this.onLearn,
  });

  final ScrollInfo info;
  final VoidCallback onStart;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = info.u;
    final compact = info.compact;
    final vw = info.vw, vh = info.vh;
    final p = info.pin;
    final a = l10n.wlShowA.trim().split(' ');
    final b = l10n.wlShowB.trim().split(' ');
    final c = l10n.wlShowC.trim().split(' ');
    final words = [...a, ...b, ...c];
    final textT = seg(p, 0.0, 0.5);
    final size = (compact ? 34 : 60) * (compact ? 1.0 : u);

    final text = SizedBox(
      width: compact ? vw * 0.84 : vw * 0.42,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: seg(p, 0.0, 0.12),
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
                  l10n.wlShowEyebrow.toUpperCase(),
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
          SizedBox(height: 18 * u),
          WordReveal(
            words: words,
            t: textT,
            style: landingHeadline(size),
            accent: LandingPalette.red,
            accentFrom: a.length,
            accentTo: a.length + b.length,
          ),
          SizedBox(height: 22 * u),
          Opacity(
            opacity: seg(p, 0.35, 0.6),
            child: SizedBox(
              width: 400 * (compact ? 1 : u),
              child: Text(
                l10n.wlShowBody,
                style: landingText(
                  compact ? 14 : 15 * u + 1,
                  weight: FontWeight.w500,
                  color: LandingPalette.text,
                  height: 1.45,
                ),
              ),
            ),
          ),
          SizedBox(height: 22 * u),
          Opacity(
            opacity: seg(p, 0.45, 0.7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LandingButton(
                  l10n.wlStart,
                  onTap: onStart,
                  size: compact ? 13 : 15,
                ),
                const SizedBox(width: 8),
                LandingButton(
                  l10n.wlLearn,
                  onTap: onLearn,
                  primary: false,
                  size: compact ? 13 : 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Chồng thẻ chéo
    const n = 6;
    final cw = (compact ? 92 : 190) * (compact ? 1.0 : u);
    final stack = <Widget>[];
    for (var j = 0; j < n; j++) {
      final k = seg(p, 0.05 + j * 0.07, 0.5 + j * 0.06, Curves.easeOutCubic);
      final baseX = compact
          ? vw * 0.12 + j * cw * 0.55
          : vw * 0.50 + j * vw * 0.066;
      final baseY = compact ? vh * 0.56 + j * 14 : vh * 0.22 + j * vh * 0.062;
      stack.add(
        Positioned(
          left: baseX + (1 - k) * vw * 0.6,
          top: baseY,
          child: Opacity(
            opacity: k,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(-0.28 * (1 - k * 0.4))
                ..rotateZ(-0.05),
              child: LandingCard(
                asset: cover(6 + j * 3),
                width: cw,
                ratio: compact ? 1.3 : 1.15,
                radius: 14 * u + 2,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          left: vw * 0.08,
          top: compact ? vh * 0.12 : vh * 0.26,
          child: text,
        ),
        ...stack,
        Positioned(
          left: compact ? vw * 0.5 : vw * 0.5 + 2 * vw * 0.066 + cw * 0.5,
          top: compact ? vh * 0.5 : vh * 0.22 + 2 * vh * 0.062 - 14,
          child: Opacity(
            opacity: seg(p, 0.4, 0.6),
            child: StickerChip(l10n.wlChipShop, size: 13, angle: -0.06),
          ),
        ),
      ],
    );
  }
}

/// Cảnh 3 — "Gateway": tiêu đề, một khung ảnh cam bo góc lớn dần và trồi lên khi cuộn,
/// rồi khối "Trusted by the best" với dải tên shop (video 8–13 s).
class GatewayScene extends StatelessWidget {
  const GatewayScene({super.key, required this.info, required this.onOpen});

  final ScrollInfo info;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final u = info.u;
    final compact = info.compact;
    final vw = info.vw, vh = info.vh;
    final p = info.pin;

    final grow = seg(p, 0.0, 0.45, Curves.easeInOutCubic);
    final rise = seg(p, 0.45, 0.8, Curves.easeInOutCubic);
    final bw = lerpD(
      vw * (compact ? 0.84 : 0.62),
      vw * (compact ? 0.92 : 0.9),
      grow,
    );
    final bh = lerpD(vh * 0.40, vh * (compact ? 0.4 : 0.52), grow);
    final bTop = lerpD(vh * 0.36, vh * 0.12, rise);
    final headSize = (compact ? 32 : 58) * (compact ? 1.0 : u);
    final headOpacity = (1 - rise * 1.5).clamp(0.0, 1.0);
    final shops = [
      l10n.wlShop1,
      l10n.wlShop2,
      l10n.wlShop3,
      l10n.wlShop4,
      l10n.wlShop5,
    ];

    return Stack(
      children: [
        Positioned(
          top: vh * 0.1 - rise * 60,
          left: vw * 0.08,
          right: vw * 0.08,
          child: Opacity(
            opacity: headOpacity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: WordReveal(
                    words: l10n.wlGateTitle.split(' '),
                    t: seg(p, 0.0, 0.25),
                    style: landingHeadline(headSize),
                  ),
                ),
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Opacity(
                      opacity: seg(p, 0.1, 0.3),
                      child: StickerChip(
                        l10n.wlChipShop,
                        size: 14,
                        angle: 0.05,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Khung ảnh cam
        Positioned(
          left: (vw - bw) / 2,
          top: bTop,
          width: bw,
          height: bh,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34 * u + 4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        LandingPalette.orangeSoft,
                        LandingPalette.orange,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: bw * 0.08 + (1 - grow) * 30,
                  top: bh * 0.12 - rise * 30,
                  bottom: -bh * 0.18,
                  child: Transform.rotate(
                    angle: 0.08,
                    child: LandingCard(
                      asset: cover(2),
                      width: bh * 0.62,
                      ratio: 1.45,
                      radius: 22,
                      border: 0,
                      shadow: true,
                    ),
                  ),
                ),
                Positioned(
                  left: bw * 0.05,
                  bottom: bh * 0.07,
                  child: LandingButton(
                    l10n.wlGateCta,
                    onTap: onOpen,
                    color: LandingPalette.ink,
                    size: compact ? 12 : 14,
                  ),
                ),
                Positioned(
                  right: bw * 0.04,
                  bottom: bh * 0.07,
                  child: Row(
                    children: [
                      for (final i in [
                        Icons.arrow_back_rounded,
                        Icons.arrow_forward_rounded,
                      ])
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: LandingPalette.white.withValues(alpha: 0.28),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(i, size: 18, color: LandingPalette.white),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // "Trusted by the best"
        Positioned(
          left: vw * 0.08,
          right: vw * 0.08,
          top: lerpD(vh * 1.05, vh * 0.12 + bh + vh * 0.1, rise),
          child: Opacity(
            opacity: rise,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.wlTrustTitle,
                  style: landingHeadline(
                    (compact ? 26 : 40) * (compact ? 1 : u),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.wlTrustSub,
                  style: landingText(
                    compact ? 13 : 15,
                    weight: FontWeight.w500,
                    color: LandingPalette.text,
                  ),
                ),
                SizedBox(height: 26 * u),
                Wrap(
                  spacing: 40 * u,
                  runSpacing: 12,
                  children: [
                    for (final s in shops)
                      Text(
                        s,
                        style: landingText(
                          (compact ? 16 : 22) * (compact ? 1 : u),
                          weight: FontWeight.w700,
                          color: LandingPalette.muted,
                          spacing: -0.4,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
