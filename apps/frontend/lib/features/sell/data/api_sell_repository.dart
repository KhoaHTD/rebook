import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/sell/domain/sell_draft.dart';
import 'package:book_marketplace/features/sell/domain/sell_repository.dart';
import 'package:book_marketplace/shared/data/book_mapper.dart';
import 'package:book_marketplace/shared/domain/book.dart';

/// `POST /seller/listings` (cần đã bật shop), thể loại từ `GET /categories`.
class ApiSellRepository implements SellRepository {
  ApiSellRepository(this._client);

  final api.RestClient _client;

  @override
  Future<List<SellCategory>> listCategories() => guardApi(() async {
    final roots = await _client.catalog.getCategories();
    final result = <SellCategory>[];
    void walk(api.CategoryResponse c, String prefix) {
      final name = '$prefix${c.name ?? ''}';
      result.add(SellCategory(id: sid(c.id), name: name));
      for (final child in c.children ?? const <api.CategoryResponse>[]) {
        walk(child, '$name › ');
      }
    }

    for (final c in roots) {
      walk(c, '');
    }
    return result;
  });

  /// Backend chưa có endpoint gợi ý giá → không hiện gợi ý.
  @override
  Future<PriceSuggestion?> suggestPrice(
    String title,
    BookCondition condition,
  ) async => null;

  @override
  Future<String> createListing(SellDraft draft) => guardApi(() async {
    final publisher = draft.publisher.trim();
    final res = await _client.catalog.postSellerListings(
      body: api.ListingRequest(
        book: api.BookRequest(
          title: draft.title.trim(),
          author: draft.author.trim(),
          publisher: publisher.isEmpty ? null : publisher,
          publishYear: draft.publishYear,
          categoryId: int.parse(draft.category!.id),
          conditionGrade: draft.condition.toApi(),
          weightGram: draft.weightGram,
          imageUrls: draft.imageUrls,
        ),
        price: draft.price,
        stock: 1,
      ),
    );
    return sid(res.id);
  });
}
