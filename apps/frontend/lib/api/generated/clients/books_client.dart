// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/book_dto.dart';

part 'books_client.g.dart';

@RestApi()
abstract class BooksClient {
  factory BooksClient(Dio dio, {String? baseUrl}) = _BooksClient;

  @GET('/books')
  Future<List<BookDto>> listBooks({@Query('q') String? q});

  @GET('/books/{id}')
  Future<BookDto> getBook({@Path('id') required String id});
}
