import 'package:book_marketplace/shared/domain/user.dart';

/// Hồ sơ và sổ địa chỉ của người đang đăng nhập (SRS 5.1).
abstract interface class AccountRepository {
  Future<AppUser> me();

  Future<AppUser> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  });

  Future<List<Address>> addresses();

  /// [address] có id rỗng → tạo mới.
  Future<Address> saveAddress(Address address);

  Future<void> deleteAddress(String id);
}
