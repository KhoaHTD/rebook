import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/cart/data/api_cart_repository.dart';
import 'package:book_marketplace/features/cart/data/fake_cart_repository.dart';
import 'package:book_marketplace/features/cart/domain/cart_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'cart_repository_provider.g.dart';

@riverpod
CartRepository cartRepository(Ref ref) => Env.useMock
    ? FakeCartRepository(ref.watch(fakeStoreProvider))
    : ApiCartRepository(ref.watch(restClientProvider));
