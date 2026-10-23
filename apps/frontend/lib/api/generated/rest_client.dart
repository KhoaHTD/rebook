// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/auth_client.dart';
import 'clients/users_client.dart';
import 'clients/shops_client.dart';
import 'clients/categories_client.dart';
import 'clients/listings_client.dart';
import 'clients/seller_listings_client.dart';
import 'clients/cart_client.dart';
import 'clients/orders_client.dart';
import 'clients/seller_orders_client.dart';
import 'clients/wallet_client.dart';
import 'clients/payments_client.dart';
import 'clients/uploads_client.dart';
import 'clients/consignments_client.dart';
import 'clients/staff_client.dart';
import 'clients/auctions_client.dart';
import 'clients/notifications_client.dart';
import 'clients/admin_client.dart';

/// ReBook API `v1.0.0`
class RestClient {
  RestClient(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  AuthClient? _auth;
  UsersClient? _users;
  ShopsClient? _shops;
  CategoriesClient? _categories;
  ListingsClient? _listings;
  SellerListingsClient? _sellerListings;
  CartClient? _cart;
  OrdersClient? _orders;
  SellerOrdersClient? _sellerOrders;
  WalletClient? _wallet;
  PaymentsClient? _payments;
  UploadsClient? _uploads;
  ConsignmentsClient? _consignments;
  StaffClient? _staff;
  AuctionsClient? _auctions;
  NotificationsClient? _notifications;
  AdminClient? _admin;

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  UsersClient get users => _users ??= UsersClient(_dio, baseUrl: _baseUrl);

  ShopsClient get shops => _shops ??= ShopsClient(_dio, baseUrl: _baseUrl);

  CategoriesClient get categories =>
      _categories ??= CategoriesClient(_dio, baseUrl: _baseUrl);

  ListingsClient get listings =>
      _listings ??= ListingsClient(_dio, baseUrl: _baseUrl);

  SellerListingsClient get sellerListings =>
      _sellerListings ??= SellerListingsClient(_dio, baseUrl: _baseUrl);

  CartClient get cart => _cart ??= CartClient(_dio, baseUrl: _baseUrl);

  OrdersClient get orders => _orders ??= OrdersClient(_dio, baseUrl: _baseUrl);

  SellerOrdersClient get sellerOrders =>
      _sellerOrders ??= SellerOrdersClient(_dio, baseUrl: _baseUrl);

  WalletClient get wallet => _wallet ??= WalletClient(_dio, baseUrl: _baseUrl);

  PaymentsClient get payments =>
      _payments ??= PaymentsClient(_dio, baseUrl: _baseUrl);

  UploadsClient get uploads =>
      _uploads ??= UploadsClient(_dio, baseUrl: _baseUrl);

  ConsignmentsClient get consignments =>
      _consignments ??= ConsignmentsClient(_dio, baseUrl: _baseUrl);

  StaffClient get staff => _staff ??= StaffClient(_dio, baseUrl: _baseUrl);

  AuctionsClient get auctions =>
      _auctions ??= AuctionsClient(_dio, baseUrl: _baseUrl);

  NotificationsClient get notifications =>
      _notifications ??= NotificationsClient(_dio, baseUrl: _baseUrl);

  AdminClient get admin => _admin ??= AdminClient(_dio, baseUrl: _baseUrl);
}
