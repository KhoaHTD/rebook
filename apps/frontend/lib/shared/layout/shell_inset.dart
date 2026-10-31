import 'package:flutter/widgets.dart';

/// Bề rộng phần khung app phủ lên mép trái nội dung (sidebar kính trong suốt trên desktop).
///
/// Nội dung trang nằm dưới sidebar chứ không bị cắt ở mép sidebar, nên `AppPage` tự chừa lề trái
/// đúng bằng giá trị này, còn băng chuyền banner thì được phép chạy tràn xuống dưới sidebar
/// (bị kính mờ làm nhoè). Ngoài khung app, hoặc trên điện thoại, giá trị là 0.
class ShellInset extends InheritedWidget {
  const ShellInset({super.key, required this.left, required super.child});

  final double left;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellInset>()?.left ?? 0;

  @override
  bool updateShouldNotify(ShellInset old) => left != old.left;
}
