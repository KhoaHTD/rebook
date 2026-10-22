import 'package:book_marketplace/features/home/domain/home_feed.dart';

abstract interface class HomeRepository {
  Future<HomeFeed> getFeed();
}
