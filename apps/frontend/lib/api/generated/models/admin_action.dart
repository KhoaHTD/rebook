// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum AdminAction {
  @JsonValue('LISTING_APPROVED')
  listingApproved('LISTING_APPROVED'),
  @JsonValue('LISTING_REJECTED')
  listingRejected('LISTING_REJECTED'),
  @JsonValue('USER_LOCKED')
  userLocked('USER_LOCKED'),
  @JsonValue('USER_UNLOCKED')
  userUnlocked('USER_UNLOCKED'),
  @JsonValue('ROLE_CHANGED')
  roleChanged('ROLE_CHANGED'),
  @JsonValue('AUCTION_BAN_LIFTED')
  auctionBanLifted('AUCTION_BAN_LIFTED'),
  @JsonValue('SHOP_MARKED_TRUSTED')
  shopMarkedTrusted('SHOP_MARKED_TRUSTED'),
  @JsonValue('WITHDRAWAL_COMPLETED')
  withdrawalCompleted('WITHDRAWAL_COMPLETED'),
  @JsonValue('CONFIG_CHANGED')
  configChanged('CONFIG_CHANGED'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const AdminAction(this.json);

  factory AdminAction.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<AdminAction> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
