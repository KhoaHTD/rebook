import 'package:book_marketplace/features/sell/domain/sell_draft.dart';
import 'package:book_marketplace/shared/domain/book.dart';

abstract interface class SellRepository {
  /// Thể loại để chọn khi đăng (gồm cả thể loại con).
  Future<List<SellCategory>> listCategories();

  /// null khi chưa đủ dữ liệu để gợi ý.
  Future<PriceSuggestion?> suggestPrice(String title, BookCondition condition);

  /// Gửi tin đăng (chờ duyệt, shop uy tín được duyệt ngay). Trả về id tin.
  Future<String> createListing(SellDraft draft);
}
