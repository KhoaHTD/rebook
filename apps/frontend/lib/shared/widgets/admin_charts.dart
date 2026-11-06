import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';

/// Một đường / một nhóm cột của biểu đồ: tên, màu và giá trị theo từng mốc trục hoành.
class ChartSeries {
  const ChartSeries(this.label, this.color, this.values);

  final String label;
  final Color color;
  final List<double> values;
}

/// Hộp chú thích khi rê chuột / chạm vào một mốc: tiêu đề và các dòng "màu · tên: giá trị".
typedef ChartTooltip = List<(Color, String, String)> Function(int index);

/// Biểu đồ đường mềm có vùng tô mờ và chú thích theo mốc (như dashboard hiệu suất). Mỗi đường được co theo giá trị
/// lớn nhất của chính nó để hai đường khác thang đo (tiền và số đơn) vẫn đọc được; trục dọc hiện thang của đường đầu.
class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.labels,
    required this.series,
    required this.axisFormat,
    required this.tooltipTitle,
    required this.tooltip,
    this.height = 240,
  });

  final List<String> labels;
  final List<ChartSeries> series;
  final String Function(double) axisFormat;
  final String Function(int index) tooltipTitle;
  final ChartTooltip tooltip;
  final double height;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  static const _left = 52.0;
  static const _bottom = 26.0;
  int? _hover;

  int? _indexAt(double dx, double width) {
    final n = widget.labels.length;
    if (n == 0) return null;
    if (n == 1) return 0;
    final plot = width - _left - 8;
    final t = ((dx - _left) / plot).clamp(0.0, 1.0);
    return (t * (n - 1)).round();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.textStyles.labelSmall?.copyWith(
      color: AdminPalette.faint,
    );
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final n = widget.labels.length;
          final plotW = box.maxWidth - _left - 8;
          final plotH = widget.height - _bottom - 8;
          double xAt(int i) =>
              _left + (n <= 1 ? plotW / 2 : plotW * i / (n - 1));
          final hover = _hover;
          final tip = hover == null ? null : widget.tooltip(hover);
          final tipX = hover == null ? 0.0 : xAt(hover);
          final flip = tipX > box.maxWidth - 190;
          return MouseRegion(
            onHover: (e) => setState(
              () => _hover = _indexAt(e.localPosition.dx, box.maxWidth),
            ),
            onExit: (_) => setState(() => _hover = null),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => setState(
                () => _hover = _indexAt(d.localPosition.dx, box.maxWidth),
              ),
              onHorizontalDragUpdate: (d) => setState(
                () => _hover = _indexAt(d.localPosition.dx, box.maxWidth),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrendPainter(
                        labels: widget.labels,
                        series: widget.series,
                        axisFormat: widget.axisFormat,
                        labelStyle: style,
                        hover: hover,
                      ),
                    ),
                  ),
                  if (tip != null && hover != null)
                    Positioned(
                      left: flip ? null : tipX + 12,
                      right: flip ? box.maxWidth - tipX + 12 : null,
                      top: 6,
                      child: IgnorePointer(
                        child: _Tip(
                          title: widget.tooltipTitle(hover),
                          rows: tip,
                          maxHeight: plotH,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({
    required this.title,
    required this.rows,
    required this.maxHeight,
  });

  final String title;
  final List<(Color, String, String)> rows;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    return Container(
      constraints: BoxConstraints(maxHeight: math.max(maxHeight, 80)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AdminPalette.ink,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.labelMedium?.copyWith(
              color: AdminPalette.card,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (final (color, label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$label  ',
                    style: text.labelSmall?.copyWith(
                      color: AdminPalette.card.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    value,
                    style: text.labelSmall?.copyWith(
                      color: AdminPalette.card,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.labels,
    required this.series,
    required this.axisFormat,
    required this.labelStyle,
    required this.hover,
  });

  final List<String> labels;
  final List<ChartSeries> series;
  final String Function(double) axisFormat;
  final TextStyle? labelStyle;
  final int? hover;

  void _text(
    Canvas c,
    String s,
    Offset o, {
    bool right = false,
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = right ? o.dx - tp.width : (center ? o.dx - tp.width / 2 : o.dx);
    tp.paint(c, Offset(dx, o.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = _TrendChartState._left;
    const bottom = _TrendChartState._bottom;
    final plot = Rect.fromLTRB(left, 8, size.width - 8, size.height - bottom);
    final n = labels.length;
    final grid = Paint()
      ..color = AdminPalette.lineSoft
      ..strokeWidth = 1;
    final maxes = [
      for (final s in series)
        math.max(1.0, s.values.fold<double>(0, (a, v) => math.max(a, v))),
    ];
    // Lưới ngang và nhãn trục dọc (thang của đường đầu tiên).
    for (var i = 0; i <= 4; i++) {
      final y = plot.bottom - plot.height * i / 4;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      if (series.isNotEmpty) {
        _text(
          canvas,
          axisFormat(maxes[0] * i / 4),
          Offset(plot.left - 8, y),
          right: true,
        );
      }
    }
    if (n == 0) return;
    double xAt(int i) =>
        n == 1 ? plot.center.dx : plot.left + plot.width * i / (n - 1);
    // Nhãn trục hoành: tối đa ~7 mốc cách đều.
    final step = math.max(1, (n / 7).ceil());
    for (var i = 0; i < n; i += step) {
      _text(canvas, labels[i], Offset(xAt(i), plot.bottom + 14), center: true);
    }
    for (var si = series.length - 1; si >= 0; si--) {
      final s = series[si];
      final pts = <Offset>[
        for (var i = 0; i < n; i++)
          Offset(
            xAt(i),
            plot.bottom -
                plot.height *
                    (i < s.values.length ? s.values[i] : 0) /
                    maxes[si] *
                    0.94,
          ),
      ];
      final path = _smooth(pts);
      if (si == 0) {
        final area = Path.from(path)
          ..lineTo(pts.last.dx, plot.bottom)
          ..lineTo(pts.first.dx, plot.bottom)
          ..close();
        canvas.drawPath(
          area,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                s.color.withValues(alpha: 0.22),
                s.color.withValues(alpha: 0),
              ],
            ).createShader(plot),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final h = hover;
    if (h != null && h < n) {
      final x = xAt(h);
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = AdminPalette.line
          ..strokeWidth = 1.2,
      );
      for (var si = 0; si < series.length; si++) {
        final s = series[si];
        final v = h < s.values.length ? s.values[h] : 0;
        final y = plot.bottom - plot.height * v / maxes[si] * 0.94;
        canvas.drawCircle(
          Offset(x, y),
          5.5,
          Paint()..color = AdminPalette.card,
        );
        canvas.drawCircle(
          Offset(x, y),
          5.5,
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }
    }
  }

  /// Đường cong mượt đi qua các điểm (Catmull-Rom → Bézier, kẹp để không vọt quá điểm).
  Path _smooth(List<Offset> p) {
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = i == 0 ? p[i] : p[i - 1];
      final p1 = p[i];
      final p2 = p[i + 1];
      final p3 = i + 2 < p.length ? p[i + 2] : p2;
      final lo = math.min(p1.dy, p2.dy);
      final hi = math.max(p1.dy, p2.dy);
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        (p1.dy + (p2.dy - p0.dy) / 6).clamp(lo, hi),
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        (p2.dy - (p3.dy - p1.dy) / 6).clamp(lo, hi),
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.hover != hover || old.series != series || old.labels != labels;
}

/// Biểu đồ cột (một nhóm), mốc đang rê chuột được tô đậm và có chú thích.
class ColumnChart extends StatefulWidget {
  const ColumnChart({
    super.key,
    required this.labels,
    required this.values,
    required this.color,
    required this.valueFormat,
    this.height = 160,
  });

  final List<String> labels;
  final List<double> values;
  final Color color;
  final String Function(double) valueFormat;
  final double height;

  @override
  State<ColumnChart> createState() => _ColumnChartState();
}

class _ColumnChartState extends State<ColumnChart> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final n = widget.values.length;
    final maxV = math.max(1.0, widget.values.fold<double>(0, math.max));
    final text = context.textStyles;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final gap = n > 40 ? 1.0 : 3.0;
          final w = n == 0 ? 0.0 : (box.maxWidth - gap * (n - 1)) / n;
          final hover = _hover;
          return MouseRegion(
            onExit: (_) => setState(() => _hover = null),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < n; i++) ...[
                      if (i > 0) SizedBox(width: gap),
                      MouseRegion(
                        onEnter: (_) => setState(() => _hover = i),
                        child: GestureDetector(
                          onTap: () => setState(() => _hover = i),
                          child: SizedBox(
                            width: w,
                            height: widget.height,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                height: math.max(
                                  2,
                                  (widget.height - 4) * widget.values[i] / maxV,
                                ),
                                decoration: BoxDecoration(
                                  color: hover == null || hover == i
                                      ? widget.color
                                      : widget.color.withValues(alpha: 0.35),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hover != null && hover < n)
                  Positioned(
                    left: (hover * (w + gap) - 30).clamp(
                      0,
                      math.max(0, box.maxWidth - 110),
                    ),
                    top: 0,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AdminPalette.ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.labels[hover]} · ${widget.valueFormat(widget.values[hover])}',
                          style: text.labelSmall?.copyWith(
                            color: AdminPalette.card,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Biểu đồ tròn rỗng giữa kèm chú giải. [center] là chữ ở giữa (vd. tổng).
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    required this.valueFormat,
    this.center,
    this.size = 150,
  });

  final List<(String, double, Color)> slices;
  final String Function(double) valueFormat;
  final Widget? center;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (a, s) => a + s.$2);
    final text = context.textStyles;
    return Row(
      children: [
        SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _DonutPainter(slices, total),
              ),
              ?center,
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (label, value, color) in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        total == 0
                            ? valueFormat(value)
                            : '${valueFormat(value)} · ${(value * 100 / total).round()}%',
                        style: text.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.total);

  final List<(String, double, Color)> slices;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AdminPalette.lineSoft;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final (_, v, color) in slices) {
      final sweep = math.pi * 2 * v / total;
      if (sweep <= 0) continue;
      canvas.drawArc(
        rect,
        start,
        math.max(0, sweep - 0.04),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices || old.total != total;
}
