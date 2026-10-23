import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/wallet/data/api_wallet_repository.dart';
import 'package:book_marketplace/features/wallet/data/fake_wallet_repository.dart';
import 'package:book_marketplace/features/wallet/domain/wallet_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'wallet_repository_provider.g.dart';

@riverpod
WalletRepository walletRepository(Ref ref) => Env.useMock
    ? FakeWalletRepository(ref.watch(fakeStoreProvider))
    : ApiWalletRepository(ref.watch(restClientProvider));
