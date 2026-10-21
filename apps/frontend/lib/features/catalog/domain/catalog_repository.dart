import 'package:book_marketplace/shared/domain/book.dart';

abstract interface class CatalogRepository {
  Future<List<Book>> listBooks({String? query});

  Future<Book> getBook(String id);
}
