import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/core/auth/auth_user.dart';
import 'package:book_marketplace/shared/domain/enums.dart';

part 'user.freezed.dart';

/// Một tài khoản vừa mua vừa bán được; Staff/Admin là vai trò riêng (SRS 2).
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    required String fullName,
    required UserRole role,
    required bool phoneVerified,
    required bool hasShop,
    String? phone,
    String? avatarUrl,
    @Default(false) bool locked,
    DateTime? auctionBannedUntil,
    DateTime? createdAt,
  }) = _AppUser;
}

@freezed
abstract class Address with _$Address {
  const Address._();

  const factory Address({
    required String id,
    required String receiver,
    required String phone,
    required String province,
    required String district,
    required String ward,
    required String detail,
    required bool isDefault,

    /// Vị trí người dùng ghim trên bản đồ (null = chưa ghim, dùng tâm tỉnh / thành).
    double? latitude,
    double? longitude,
  }) = _Address;

  bool get hasPin => latitude != null && longitude != null;

  String get oneLine => '$detail, $ward, $district, $province';
}

@freezed
abstract class ShopSummary with _$ShopSummary {
  const factory ShopSummary({
    required String id,
    required String name,
    required double ratingAvg,
    required int ratingCount,
    String? avatarUrl,
  }) = _ShopSummary;
}

@freezed
abstract class Shop with _$Shop {
  const factory Shop({
    required String id,
    required String userId,
    required String name,
    required String pickupAddress,
    required double ratingAvg,
    required int ratingCount,
    required DateTime createdAt,
    String? avatarUrl,
    String? description,
    @Default(0) int activeListings,
  }) = _Shop;
}

/// Thông tin mở shop: tên, địa chỉ lấy hàng, tài khoản nhận tiền (SRS 2).
@freezed
abstract class ShopDraft with _$ShopDraft {
  const factory ShopDraft({
    required String name,
    required String pickupAddress,
    required String bankName,
    required String bankAccount,
    required String bankHolder,
    String? description,
  }) = _ShopDraft;
}

@freezed
abstract class SellerStats with _$SellerStats {
  const factory SellerStats({
    required int revenueTotal,
    required int revenueThisMonth,
    required int pendingBalance,
    required int ordersToConfirm,
    required int ordersShipping,
    required int ordersCompleted,
    required int activeListings,
    required double ratingAvg,
  }) = _SellerStats;
}

/// Thông tin rút gọn lưu vào phiên đăng nhập.
extension AppUserAuth on AppUser {
  AuthUser toAuthUser() => AuthUser(
    id: id,
    email: email,
    fullName: fullName,
    role: switch (role) {
      UserRole.user => AuthRole.user,
      UserRole.staff => AuthRole.staff,
      UserRole.admin => AuthRole.admin,
    },
    hasShop: hasShop,
    avatarUrl: avatarUrl,
  );
}
