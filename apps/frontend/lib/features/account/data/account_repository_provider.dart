import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/account/data/api_account_repository.dart';
import 'package:book_marketplace/features/account/data/fake_account_repository.dart';
import 'package:book_marketplace/features/account/domain/account_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'account_repository_provider.g.dart';

@riverpod
AccountRepository accountRepository(Ref ref) => Env.useMock
    ? FakeAccountRepository(ref.watch(fakeStoreProvider))
    : ApiAccountRepository(ref.watch(restClientProvider));
