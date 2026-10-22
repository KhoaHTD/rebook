import 'package:book_marketplace/features/account/domain/account_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository(this._store);

  final FakeStore _store;

  @override
  Future<AppUser> me() => fakeCall(() => _store.me);

  @override
  Future<AppUser> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) => fakeCall(
    () => _store.updateProfile(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    ),
  );

  @override
  Future<List<Address>> addresses() => fakeCall(_store.myAddresses);

  @override
  Future<Address> saveAddress(Address address) =>
      fakeCall(() => _store.saveAddress(address));

  @override
  Future<void> deleteAddress(String id) =>
      fakeCall(() => _store.deleteAddress(id));
}
