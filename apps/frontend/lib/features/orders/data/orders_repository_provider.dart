import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/orders/data/api_orders_repository.dart';
import 'package:book_marketplace/features/orders/data/fake_orders_repository.dart';
import 'package:book_marketplace/features/orders/domain/orders_repository.dart';
import 'package:book_marketplace/shared/data/fake/fake_store.dart';

part 'orders_repository_provider.g.dart';

@riverpod
OrdersRepository ordersRepository(Ref ref) => Env.useMock
    ? FakeOrdersRepository(ref.watch(fakeStoreProvider))
    : ApiOrdersRepository(ref.watch(restClientProvider));
