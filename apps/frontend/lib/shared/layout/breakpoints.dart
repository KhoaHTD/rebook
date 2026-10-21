import 'package:flutter/widgets.dart';

/// Theo Material 3 window size classes.
enum WindowSize {
  /// Điện thoại dọc (< 600)
  compact,

  /// Tablet, điện thoại ngang (600–1023)
  medium,

  /// Desktop web (≥ 1024)
  expanded;

  bool get isCompact => this == compact;
  bool get isAtLeastMedium => this != compact;
}

abstract final class Breakpoints {
  static const medium = 600.0;
  static const expanded = 1024.0;

  /// Bề rộng tối đa của nội dung chính trên màn lớn.
  static const maxContentWidth = 1200.0;

  static WindowSize of(double width) {
    if (width >= expanded) return WindowSize.expanded;
    if (width >= medium) return WindowSize.medium;
    return WindowSize.compact;
  }
}

extension WindowSizeX on BuildContext {
  WindowSize get windowSize => Breakpoints.of(MediaQuery.sizeOf(this).width);
}

/// Căn giữa nội dung và giới hạn bề rộng trên web.
class MaxWidthBox extends StatelessWidget {
  const MaxWidthBox({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
