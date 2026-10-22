// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/consignment_client.dart';
import 'clients/catalog_client.dart';
import 'clients/user_client.dart';
import 'clients/auction_client.dart';
import 'clients/order_client.dart';
import 'clients/admin_client.dart';
import 'clients/wallet_client.dart';
import 'clients/order_management_client.dart';
import 'clients/notification_client.dart';
import 'clients/auth_client.dart';

/// ReBook API `v0.1.0`.
///
/// Chợ sách cũ: bán giá cố định + đấu giá. Realtime đấu giá qua WebSocket ws://<host>/ws/sessions/{id}.
class RestClient {
  RestClient(Dio dio, {String? baseUrl}) : _dio = dio, _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.1.0';

  ConsignmentClient? _consignment;
  CatalogClient? _catalog;
  UserClient? _user;
  AuctionClient? _auction;
  OrderClient? _order;
  AdminClient? _admin;
  WalletClient? _wallet;
  OrderManagementClient? _orderManagement;
  NotificationClient? _notification;
  AuthClient? _auth;

  ConsignmentClient get consignment =>
      _consignment ??= ConsignmentClient(_dio, baseUrl: _baseUrl);

  CatalogClient get catalog =>
      _catalog ??= CatalogClient(_dio, baseUrl: _baseUrl);

  UserClient get user => _user ??= UserClient(_dio, baseUrl: _baseUrl);

  AuctionClient get auction =>
      _auction ??= AuctionClient(_dio, baseUrl: _baseUrl);

  OrderClient get order => _order ??= OrderClient(_dio, baseUrl: _baseUrl);

  AdminClient get admin => _admin ??= AdminClient(_dio, baseUrl: _baseUrl);

  WalletClient get wallet => _wallet ??= WalletClient(_dio, baseUrl: _baseUrl);

  OrderManagementClient get orderManagement =>
      _orderManagement ??= OrderManagementClient(_dio, baseUrl: _baseUrl);

  NotificationClient get notification =>
      _notification ??= NotificationClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);
}
