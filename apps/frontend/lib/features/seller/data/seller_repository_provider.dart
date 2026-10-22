import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/seller/data/api_seller_repository.dart';
import 'package:book_marketplace/features/seller/data/fake_seller_repository.dart';
import 'package:book_marketplace/features/seller/domain/seller_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'seller_repository_provider.g.dart';

@riverpod
SellerRepository sellerRepository(Ref ref) => Env.useMock
    ? FakeSellerRepository(ref.watch(fakeStoreProvider))
    : ApiSellerRepository(ref.watch(restClientProvider));
