import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/sell/domain/sell_draft.dart';
import 'package:book_marketplace/features/sell/domain/sell_repository.dart';
import 'package:book_marketplace/shared/domain/book.dart';

class FakeSellRepository implements SellRepository {
  FakeSellRepository({this.latency = const Duration(milliseconds: 300)});

  final Duration latency;
  final created = <SellDraft>[];

  static const _ranges = {
    BookCondition.brandNew: PriceSuggestion(low: 75000, high: 90000),
    BookCondition.likeNew: PriceSuggestion(low: 55000, high: 70000),
    BookCondition.veryGood: PriceSuggestion(low: 45000, high: 60000),
    BookCondition.good: PriceSuggestion(low: 30000, high: 45000),
    BookCondition.acceptable: PriceSuggestion(low: 15000, high: 25000),
  };

  @override
  Future<List<SellCategory>> listCategories() async {
    await Future<void>.delayed(latency);
    return const [
      SellCategory(id: '2', name: 'Văn học › Tiểu thuyết Việt Nam'),
      SellCategory(id: '3', name: 'Văn học › Văn học nước ngoài'),
      SellCategory(id: '5', name: 'Giáo trình › Công nghệ thông tin'),
      SellCategory(id: '7', name: 'Kỹ năng sống'),
      SellCategory(id: '9', name: 'Thiếu nhi'),
    ];
  }

  @override
  Future<PriceSuggestion?> suggestPrice(
    String title,
    BookCondition condition,
  ) async {
    await Future<void>.delayed(latency);
    if (title.trim().isEmpty) return null;
    return _ranges[condition];
  }

  @override
  Future<String> createListing(SellDraft draft) async {
    await Future<void>.delayed(latency);
    if (!draft.isValid) throw const ServerException(400, 'Invalid listing');
    created.add(draft);
    return 'new-${created.length}';
  }
}
