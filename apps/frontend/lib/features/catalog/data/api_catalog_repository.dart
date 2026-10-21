import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/shared/data/book_mapper.dart';
import 'package:book_marketplace/shared/domain/book.dart';

class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._client);

  final api.RestClient _client;

  @override
  Future<List<Book>> listBooks({String? query}) => guardApi(() async {
    final dtos = await _client.books.listBooks(q: query);
    return dtos.map((d) => d.toDomain()).toList();
  });

  @override
  Future<Book> getBook(String id) => guardApi(() async {
    final dto = await _client.books.getBook(id: id);
    return dto.toDomain();
  });
}
