import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/features/sell/data/api_sell_repository.dart';
import 'package:book_marketplace/features/sell/data/fake_sell_repository.dart';
import 'package:book_marketplace/features/sell/domain/sell_repository.dart';

part 'sell_repository_provider.g.dart';

/// Presentation chỉ import file này, không import trực tiếp Api/Fake repository.
@Riverpod(keepAlive: true)
SellRepository sellRepository(Ref ref) => Env.useMock
    ? FakeSellRepository()
    : ApiSellRepository(ref.watch(restClientProvider));
