import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/auth/data/api_auth_repository.dart';
import 'package:book_marketplace/features/auth/data/fake_auth_repository.dart';
import 'package:book_marketplace/features/auth/domain/auth_repository.dart';

part 'auth_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => Env.useMock
    ? FakeAuthRepository()
    : ApiAuthRepository(ref.watch(restClientProvider));
