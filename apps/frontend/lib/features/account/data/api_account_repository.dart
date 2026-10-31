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
      guardApi(() async => (await _client.users.getMe()).toDomain());

  @override
  Future<AppUser> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) => guardApi(
    () async => (await _client.users.updateMe(
      body: api.UpdateProfileRequest(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      ),
    )).toDomain(),
  );

  @override
  Future<List<Address>> addresses() => guardApi(
    () async =>
        (await _client.users.listAddresses()).map((a) => a.toDomain()).toList(),
  );

  @override
  Future<Address> saveAddress(Address address) => guardApi(() async {
    final body = address.toRequest();
    final dto = address.id.isEmpty
        ? await _client.users.createAddress(body: body)
        : await _client.users.updateAddress(id: address.id, body: body);
    return dto.toDomain();
  });

  @override
  Future<void> deleteAddress(String id) =>
      guardApi(() => _client.users.deleteAddress(id: id));
}
