import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/app/env.dart';
import 'package:book_marketplace/core/network/api_providers.dart';
import 'package:book_marketplace/core/realtime/realtime_client.dart';
import 'package:book_marketplace/features/auction/data/api_auction_repository.dart';
import 'package:book_marketplace/features/auction/data/fake_auction_repository.dart';
import 'package:book_marketplace/features/auction/domain/auction_repository.dart';

part 'auction_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AuctionRepository auctionRepository(Ref ref) => Env.useMock
    ? FakeAuctionRepository()
    : ApiAuctionRepository(
        ref.watch(restClientProvider),
        ref.watch(realtimeClientProvider),
      );
