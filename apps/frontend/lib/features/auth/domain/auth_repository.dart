import 'package:book_marketplace/core/auth/auth_tokens.dart';

abstract interface class AuthRepository {
  Future<AuthTokens> login({required String email, required String password});
}
