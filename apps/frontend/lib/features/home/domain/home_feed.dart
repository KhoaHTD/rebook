import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/shared/domain/book.dart';

part 'home_feed.freezed.dart';

/// Nội dung Trang chủ cho cả hai kênh: Mua sách và Đấu giá.
@freezed
abstract class HomeFeed with _$HomeFeed {
  const factory HomeFeed({
    FeaturedCollection? collection,
    @Default(<Book>[]) List<Book> newListings,
    @Default(<HomeCategory>[]) List<HomeCategory> categories,
    LotTeaser? liveLot,
    @Default(<SessionTeaser>[]) List<SessionTeaser> upcomingSessions,
    @Default(<LotTeaser>[]) List<LotTeaser> featuredLots,
  }) = _HomeFeed;
}

@freezed
abstract class FeaturedCollection with _$FeaturedCollection {
  const factory FeaturedCollection({
    required String title,
    required String subtitle,
    @Default(<String>[]) List<String> coverUrls,
  }) = _FeaturedCollection;
}

@freezed
abstract class HomeCategory with _$HomeCategory {
  const factory HomeCategory({required String id, required String name}) =
      _HomeCategory;
}

/// Tóm tắt một lô đấu giá để hiện trên Trang chủ.
@freezed
abstract class LotTeaser with _$LotTeaser {
  const factory LotTeaser({
    required String id,
    required String title,
    required String author,
    String? imageUrl,
    int? lotNumber,
    int? lotCount,
    String? sessionTitle,
    int? estimateLow,
    int? estimateHigh,
    required int currentPrice,
    required DateTime endsAt,
  }) = _LotTeaser;
}

/// Phiên sắp tới; [firstLotId] mở catalogue lô đầu tiên của phiên.
@freezed
abstract class SessionTeaser with _$SessionTeaser {
  const factory SessionTeaser({
    required String firstLotId,
    required String title,
    required DateTime startsAt,
    required int lotCount,
    int? deposit,
  }) = _SessionTeaser;
}
