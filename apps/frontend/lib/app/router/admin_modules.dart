import 'package:book_marketplace/app/router/admin_module.dart';
import 'package:book_marketplace/features/admin/presentation/admin_module.dart';
import 'package:book_marketplace/features/staff/presentation/staff_module.dart';

/// Danh sách module của web quản trị. Thêm module mới thì thêm vào đây (hạ tầng router: chủ repo duyệt).
/// Người làm Admin và Staff thường chỉ sửa trong module của mình.
final adminModules = <AdminModule>[staffModule, adminModule];
