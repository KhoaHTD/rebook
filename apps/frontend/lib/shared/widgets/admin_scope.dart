import 'package:flutter/widgets.dart';

/// Đánh dấu cây widget thuộc giao diện quản trị (Staff / Admin): `Glass` và `AppPage`
/// vẽ kiểu dashboard sáng, phẳng thay cho kính của app người mua.
class AdminScope extends InheritedWidget {
  const AdminScope({super.key, required super.child, this.onMenu});

  /// Có giá trị khi màn hình hẹp (điện thoại): sidebar thành ngăn kéo, thanh đầu trang hiện nút mở nó.
  final VoidCallback? onMenu;

  static bool active(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AdminScope>() != null;

  static VoidCallback? menuOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminScope>()?.onMenu;

  @override
  bool updateShouldNotify(AdminScope oldWidget) =>
      (onMenu == null) != (oldWidget.onMenu == null);
}
