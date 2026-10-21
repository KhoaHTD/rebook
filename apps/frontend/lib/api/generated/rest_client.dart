// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/auth_client.dart';
import 'clients/books_client.dart';
import 'clients/auctions_client.dart';

/// Book Marketplace API `v0.1.0`
class RestClient {
  RestClient(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0';

  AuthClient? _auth;
  BooksClient? _books;
  AuctionsClient? _auctions;

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  BooksClient get books => _books ??= BooksClient(_dio, baseUrl: _baseUrl);

  AuctionsClient get auctions =>
      _auctions ??= AuctionsClient(_dio, baseUrl: _baseUrl);
}
