import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:book_marketplace/app/theme/app_tokens.dart';
import 'package:book_marketplace/shared/widgets/glass.dart';

/// Mặt kính nổi cho hộp xổ xuống / popup: nền sáng đủ đặc để đọc chữ, làm mờ phía sau,
/// viền sáng mảnh, bo góc lớn và bóng mềm. Dùng chung cho app người mua và giao diện quản trị.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final base = context.colors.surface;
    // Web trên điện thoại không làm mờ nền (nặng) → nền đặc hơn để chữ vẫn đọc rõ.
    final blurred = !lightEffects;
    final top = base.withValues(alpha: blurred ? 0.74 : 0.96);
    final bottom = base.withValues(alpha: blurred ? 0.64 : 0.93);
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(c.glassTop, top),
            Color.alphaBlend(c.glassBottom, bottom),
          ],
        ),
        border: Border.all(color: c.glassBorder),
      ),
      child: child,
    );
    if (blurred) {
      body = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(filter: Glass.filter, child: body),
      );
    } else {
      body = ClipRRect(borderRadius: borderRadius, child: body);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: c.glassShadow,
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: body,
    );
  }
}

/// Một mục trong menu kính. [child] thay cho [label] khi cần dựng riêng (vd. từ `PopupMenuItem`).
class GlassMenuItem<T> {
  const GlassMenuItem({
    required this.value,
    this.label,
    this.child,
    this.icon,
    this.enabled = true,
  }) : assert(label != null || child != null);

  final T value;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final bool enabled;
}

/// Mở menu kính bo góc ngay dưới (hoặc trên) [anchor]. Trả về `({value})` khi chọn một mục,
/// `null` khi bấm ra ngoài — nhờ vậy vẫn chọn được mục có giá trị `null`.
Future<({T value})?> showGlassMenu<T>(
  BuildContext context, {
  required List<GlassMenuItem<T>> items,
  required Rect anchor,
  T? selected,
  bool hasSelected = false,
  double minWidth = 0,
}) {
  return showGeneralDialog<({T value})>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: AppDurations.fast,
    pageBuilder: (dialogContext, _, _) => CustomSingleChildLayout(
      delegate: _MenuLayout(anchor, minWidth),
      child: _MenuPanel<T>(
        items: items,
        selected: selected,
        hasSelected: hasSelected,
      ),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          alignment: Alignment.topCenter,
          child: child,
        ),
      );
    },
  );
}

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout(this.anchor, this.minWidth);

  final Rect anchor;
  final double minWidth;
  static const _margin = 10.0;
  static const _gap = 6.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxW = constraints.maxWidth - _margin * 2;
    final w = math.min(math.max(anchor.width, math.max(minWidth, 200.0)), maxW);
    final below = constraints.maxHeight - anchor.bottom - _gap - _margin;
    final above = anchor.top - _gap - _margin;
    final room = math.max(below, above);
    return BoxConstraints(
      minWidth: w,
      maxWidth: w,
      maxHeight: math.max(120.0, math.min(room, 380.0)),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.left;
    // Nút nằm sát mép phải (vd. "•••"): căn mép phải với nút.
    if (x + childSize.width > size.width - _margin) {
      x = anchor.right - childSize.width;
    }
    x = x.clamp(
      _margin,
      math.max(_margin, size.width - childSize.width - _margin),
    );
    final below = size.height - anchor.bottom - _gap - _margin;
    final fitsBelow = childSize.height <= below;
    final y = fitsBelow
        ? anchor.bottom + _gap
        : math.max(_margin, anchor.top - _gap - childSize.height);
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      old.anchor != anchor || old.minWidth != minWidth;
}

class _MenuPanel<T> extends StatelessWidget {
  const _MenuPanel({
    required this.items,
    required this.selected,
    required this.hasSelected,
  });

  final List<GlassMenuItem<T>> items;
  final T? selected;
  final bool hasSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      type: MaterialType.transparency,
      child: GlassSurface(
        child: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(6),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final item = items[i];
            final isSelected = hasSelected && item.value == selected;
            return InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              onTap: item.enabled
                  ? () => Navigator.of(
                      context,
                      rootNavigator: true,
                    ).pop((value: item.value))
                  : null,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  color: isSelected ? c.fill : null,
                ),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 20, color: c.secondaryText),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : null,
                          color: item.enabled ? null : c.tertiaryText,
                        ),
                        child:
                            item.child ??
                            Text(
                              item.label!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: context.colors.onSurface,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Mở menu kính khi chạm vào [child] (thay `PopupMenuButton`).
class GlassMenuButton<T> extends StatelessWidget {
  const GlassMenuButton({
    super.key,
    required this.items,
    required this.onSelected,
    required this.child,
    this.tooltip,
    this.selected,
    this.hasSelected = false,
  });

  final List<GlassMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget child;
  final String? tooltip;
  final T? selected;
  final bool hasSelected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final box = context.findRenderObject() as RenderBox;
          final anchor = box.localToGlobal(Offset.zero) & box.size;
          final picked = await showGlassMenu<T>(
            context,
            items: items,
            anchor: anchor,
            selected: selected,
            hasSelected: hasSelected,
          );
          if (picked != null) onSelected(picked.value);
        },
        child: MouseRegion(cursor: SystemMouseCursors.click, child: child),
      ),
    );
  }
}

/// Ô chọn một giá trị bằng menu kính (thay `DropdownButtonFormField`): nhãn nổi như ô nhập,
/// bấm vào mở danh sách kính bo góc ngay dưới ô.
class GlassDropdownField<T> extends FormField<T> {
  GlassDropdownField({
    super.key,
    required String label,
    required List<GlassMenuItem<T>> items,
    required ValueChanged<T> onChanged,
    T? value,
    String? hint,
    super.validator,
  }) : super(
         initialValue: value,
         builder: (state) {
           // Giá trị hiện tại luôn lấy từ widget cha (setState) để khớp với `value` mới nhất.
           final current = value;
           GlassMenuItem<T>? picked;
           for (final it in items) {
             if (it.value == current) picked = it;
           }
           final context = state.context;
           final text = context.textStyles.bodyMedium;
           return Builder(
             builder: (context) => InkWell(
               borderRadius: AppRadius.card,
               onTap: () async {
                 final box = context.findRenderObject() as RenderBox;
                 final anchor = box.localToGlobal(Offset.zero) & box.size;
                 final res = await showGlassMenu<T>(
                   context,
                   items: items,
                   anchor: anchor,
                   selected: current,
                   hasSelected: picked != null,
                 );
                 if (res == null) return;
                 state.didChange(res.value);
                 onChanged(res.value);
               },
               child: InputDecorator(
                 isEmpty: picked == null,
                 decoration: InputDecoration(
                   labelText: label,
                   hintText: hint,
                   errorText: state.errorText,
                   suffixIcon: const Icon(Icons.expand_more_rounded),
                 ),
                 child: picked == null
                     ? const SizedBox.shrink()
                     : DefaultTextStyle.merge(
                         style: text,
                         child:
                             picked.child ??
                             Text(
                               picked.label!,
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                       ),
               ),
             ),
           );
         },
       );
}
