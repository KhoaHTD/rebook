import 'package:book_marketplace/app/router/admin_module.dart';
import 'package:book_marketplace/features/admin/presentation/admin_module.dart';
import 'package:book_marketplace/features/staff/presentation/staff_module.dart';

/// Danh sách module của web quản trị. File này thuộc vùng khoá: thêm module mới phải qua chủ repo.
/// Hai người làm Admin và Staff chỉ sửa trong module của mình.
final adminModules = <AdminModule>[staffModule, adminModule];
