import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:book_marketplace/features/home/data/home_repository_provider.dart';
import 'package:book_marketplace/features/home/domain/home_feed.dart';

part 'home_providers.g.dart';

enum HomeChannel { buy, auction }

@riverpod
Future<HomeFeed> homeFeed(Ref ref) =>
    ref.watch(homeRepositoryProvider).getFeed();

/// Kênh đang xem trên Trang chủ (giữ khi chuyển tab qua lại).
@Riverpod(keepAlive: true)
class HomeChannelSelection extends _$HomeChannelSelection {
  @override
  HomeChannel build() => HomeChannel.buy;

  void select(HomeChannel channel) => state = channel;
}
