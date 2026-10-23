import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/core/auth/session_controller.dart';
import 'package:book_marketplace/core/utils/data_changes.dart';
import 'package:book_marketplace/features/account/data/account_repository_provider.dart';
import 'package:book_marketplace/shared/domain/user.dart';

part 'account_providers.g.dart';

@riverpod
Future<AppUser> profile(Ref ref) {
  ref.watchArea(DataArea.profile);
  return ref.watch(accountRepositoryProvider).me();
}

@riverpod
Future<List<Address>> addressBook(Ref ref) {
  ref.watchArea(DataArea.profile);
  return ref.watch(accountRepositoryProvider).addresses();
}

/// Sửa hồ sơ / địa chỉ. Đổi tên, ảnh → cập nhật luôn phiên đăng nhập.
@riverpod
class AccountController extends _$AccountController {
  @override
  FutureOr<void> build() {}

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    if (!state.hasError) {
      ref.read(dataChangesProvider.notifier).bump(DataArea.profile);
    }
    return !state.hasError;
  }

  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) => _run(() async {
    final user = await ref
        .read(accountRepositoryProvider)
        .updateProfile(fullName: fullName, phone: phone, avatarUrl: avatarUrl);
    await ref
        .read(sessionControllerProvider.notifier)
        .updateUser(user.toAuthUser());
  });

  Future<bool> saveAddress(Address address) =>
      _run(() => ref.read(accountRepositoryProvider).saveAddress(address));

  Future<bool> deleteAddress(String id) =>
      _run(() => ref.read(accountRepositoryProvider).deleteAddress(id));

  Future<void> signOut() =>
      ref.read(sessionControllerProvider.notifier).signOut();
}
