import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/account/domain/account_repository.dart';
import 'package:book_marketplace/shared/data/api_mappers.dart';
import 'package:book_marketplace/shared/domain/user.dart';

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this._client);

  final api.RestClient _client;

  @override
  Future<AppUser> me() =>
      guardApi(() async => (await _client.user.getMe()).toDomain());

  @override
  Future<AppUser> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) => guardApi(
    () async => (await _client.user.putMe(
      body: api.UpdateProfileRequest(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      ),
    )).toDomain(),
  );

  @override
  Future<List<Address>> addresses() => guardApi(
    () async => [
      for (final a in await _client.user.getMeAddresses()) a.toDomain(),
    ],
  );

  /// Địa chỉ mới do app tạo có id không phải số → POST; còn lại PUT.
  @override
  Future<Address> saveAddress(Address address) => guardApi(() async {
    final id = int.tryParse(address.id);
    final saved = id == null
        ? await _client.user.postMeAddresses(body: address.toRequest())
        : await _client.user.putMeAddressesId(
            id: id,
            body: address.toRequest(),
          );
    return saved.toDomain();
  });

  @override
  Future<void> deleteAddress(String id) =>
      guardApi(() => _client.user.deleteMeAddressesId(id: apiId(id)));
}
