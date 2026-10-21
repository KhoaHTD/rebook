import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/features/catalog/domain/catalog_repository.dart';
import 'package:book_marketplace/shared/data/fake_books.dart';
import 'package:book_marketplace/shared/domain/book.dart';

class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  @override
  Future<List<Book>> listBooks({String? query}) async {
    await Future<void>.delayed(latency);
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isEmpty) return fakeBooks;
    return fakeBooks
        .where(
          (b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Future<Book> getBook(String id) async {
    await Future<void>.delayed(latency);
    return fakeBooks.firstWhere(
      (b) => b.id == id,
      orElse: () => throw const ServerException(404, 'Book not found'),
    );
  }
}
