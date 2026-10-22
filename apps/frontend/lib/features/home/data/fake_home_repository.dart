import 'package:book_marketplace/features/home/domain/home_feed.dart';
import 'package:book_marketplace/features/home/domain/home_repository.dart';
import 'package:book_marketplace/shared/data/fake_books.dart';

class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({
    this.latency = const Duration(milliseconds: 350),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Duration latency;
  final DateTime Function() _now;

  @override
  Future<HomeFeed> getFeed() async {
    await Future<void>.delayed(latency);
    final now = _now();
    final sessionDay = DateTime(now.year, now.month, now.day + 2, 19, 30);
    return HomeFeed(
      collection: FeaturedCollection(
        title: 'Văn học Việt trước 1975',
        subtitle: 'Tuyển chọn từ các shop uy tín',
        coverUrls: [
          for (final b in fakeBooks.take(3))
            if (b.imageUrl != null) b.imageUrl!,
        ],
      ),
      newListings: fakeBooks,
      categories: const [
        HomeCategory(id: 'tieu-thuyet-viet-nam', name: 'Văn học Việt'),
        HomeCategory(id: 'giao-trinh', name: 'Giáo trình'),
        HomeCategory(id: 'thieu-nhi', name: 'Thiếu nhi'),
        HomeCategory(id: 'van-hoc-nuoc-ngoai', name: 'Ngoại văn'),
      ],
      liveLot: LotTeaser(
        id: 'a1',
        title: 'Gió đầu mùa',
        author: 'Thạch Lam',
        imageUrl: 'https://picsum.photos/seed/giodaumua/400/600',
        lotNumber: 5,
        lotCount: 20,
        sessionTitle: 'Phiên Tự Lực văn đoàn',
        currentPrice: 1200000,
        endsAt: now.add(const Duration(seconds: 42)),
      ),
      upcomingSessions: [
        SessionTeaser(
          firstLotId: 'a2',
          title: 'Sách quý trước 1975',
          startsAt: sessionDay,
          lotCount: 24,
          deposit: 500000,
        ),
        SessionTeaser(
          firstLotId: 'a4',
          title: 'Từ điển & sách khảo cứu',
          startsAt: sessionDay.add(const Duration(days: 7, minutes: 30)),
          lotCount: 18,
          deposit: 300000,
        ),
      ],
      featuredLots: [
        LotTeaser(
          id: 'a2',
          title: 'Vang bóng một thời',
          author: 'Nguyễn Tuân',
          imageUrl: 'https://picsum.photos/seed/vangbong/400/600',
          lotNumber: 7,
          estimateLow: 3000000,
          estimateHigh: 4500000,
          currentPrice: 1500000,
          endsAt: sessionDay,
        ),
        LotTeaser(
          id: 'a3',
          title: 'Việt Nam sử lược',
          author: 'Trần Trọng Kim',
          imageUrl: 'https://picsum.photos/seed/suluoc/400/600',
          lotNumber: 12,
          estimateLow: 2000000,
          estimateHigh: 3000000,
          currentPrice: 1000000,
          endsAt: sessionDay,
        ),
        LotTeaser(
          id: 'a4',
          title: 'Thơ thơ',
          author: 'Xuân Diệu',
          imageUrl: 'https://picsum.photos/seed/thotho/400/600',
          lotNumber: 15,
          estimateLow: 1000000,
          estimateHigh: 2000000,
          currentPrice: 600000,
          endsAt: sessionDay,
        ),
      ],
    );
  }
}
