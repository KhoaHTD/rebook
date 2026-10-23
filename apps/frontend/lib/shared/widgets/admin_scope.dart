import 'package:flutter/widgets.dart';

/// Đánh dấu cây widget thuộc giao diện quản trị (Staff / Admin): `Glass` và `AppPage`
/// vẽ kiểu dashboard sáng, phẳng thay cho kính của app người mua.
class AdminScope extends InheritedWidget {
  const AdminScope({super.key, required super.child});

  static bool active(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AdminScope>() != null;

  @override
  bool updateShouldNotify(AdminScope oldWidget) => false;
}
