import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/shared/data/book_mapper.dart';
import 'package:book_marketplace/shared/domain/book.dart';

/// Tin đăng bán giá cố định: `GET /listings`, `GET /listings/{id}`.
class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._client);

  final api.RestClient _client;

  /// Lấy một trang lớn; lọc tình trạng / giá / sắp xếp làm tại chỗ (xem BookSearchFilter).
  static const _pageSize = 100;

  @override
  Future<List<Book>> listBooks({String? query}) => guardApi(() async {
    final page = await _client.catalog.getListings(q: query, size: _pageSize);
    return (page.items ?? const []).map((l) => l.toBook()).toList();
  });

  @override
  Future<Book> getBook(String id) => guardApi(() async {
    final dto = await _client.catalog.getListingsId(id: int.parse(id));
    return dto.toBook();
  });
}
