/// Chuyển đổi DTO (sinh từ openapi.yaml) ↔ entity trong shared/domain.
/// Backend đổi tên trường → chỉ sửa file này; entity và UI giữ nguyên.
library;

import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/rules.dart';
import 'package:book_marketplace/shared/domain/user.dart';

/// Map enum sinh tự động sang enum domain cùng tên (camelCase).
D _enum<D extends Enum>(List<D> values, Enum g, D fallback) {
  final name = switch (g.name) {
    'valueNew' => 'brandNew',
    'valueReturn' => 'returnToSeller',
    final n => n,
  };
  return values.where((v) => v.name == name).firstOrNull ?? fallback;
}

/// Map enum domain sang enum sinh tự động (để gửi lên API).
G toApiEnum<G extends Enum>(List<G> values, Enum d) {
  final name = switch (d.name) {
    'brandNew' => 'valueNew',
    'returnToSeller' => 'valueReturn',
    final n => n,
  };
  return values.firstWhere((v) => v.name == name);
}

// ───────────────────────── enums ─────────────────────────

extension ConditionGradeApi on api.ConditionGrade {
  ConditionGrade toDomain() =>
      _enum(ConditionGrade.values, this, ConditionGrade.unknown);
}

extension OrderStatusApi on api.OrderStatus {
  OrderStatus toDomain() =>
      _enum(OrderStatus.values, this, OrderStatus.pendingConfirm);
}

extension LotStatusApi on api.LotStatus {
  LotStatus toDomain() => _enum(LotStatus.values, this, LotStatus.ready);
}

extension SessionStatusApi on api.SessionStatus {
  SessionStatus toDomain() =>
      _enum(SessionStatus.values, this, SessionStatus.published);
}

// ───────────────────────── users ─────────────────────────

extension UserDtoMapper on api.UserDto {
  AppUser toDomain() => AppUser(
    id: id,
    email: email,
    fullName: fullName,
    role: _enum(UserRole.values, role, UserRole.user),
    phoneVerified: phoneVerified,
    hasShop: hasShop,
    phone: phone,
    avatarUrl: avatarUrl,
    locked: status == api.UserStatus.locked,
    auctionBannedUntil: auctionBannedUntil,
    createdAt: createdAt,
  );
}

extension AddressDtoMapper on api.AddressDto {
  Address toDomain() => Address(
    id: id,
    receiver: receiver,
    phone: phone,
    province: province,
    district: district,
    ward: ward,
    detail: detail,
    isDefault: isDefault,
  );
}

extension AddressToApi on Address {
  api.AddressRequest toRequest() => api.AddressRequest(
    receiver: receiver,
    phone: phone,
    province: province,
    district: district,
    ward: ward,
    detail: detail,
    isDefault: isDefault,
  );
}

extension ShopSummaryDtoMapper on api.ShopSummaryDto {
  ShopSummary toDomain() => ShopSummary(
    id: id,
    name: name,
    ratingAvg: ratingAvg,
    ratingCount: ratingCount,
    avatarUrl: avatarUrl,
  );
}

extension ShopDtoMapper on api.ShopDto {
  Shop toDomain() => Shop(
    id: id,
    userId: userId,
    name: name,
    pickupAddress: pickupAddress,
    ratingAvg: ratingAvg,
    ratingCount: ratingCount,
    createdAt: createdAt,
    avatarUrl: avatarUrl,
    description: description,
    activeListings: activeListings ?? 0,
  );
}

extension ShopDraftToApi on ShopDraft {
  api.ShopRequest toRequest() => api.ShopRequest(
    name: name,
    pickupAddress: pickupAddress,
    bankName: bankName,
    bankAccount: bankAccount,
    bankHolder: bankHolder,
    description: description,
  );
}

extension SellerStatsDtoMapper on api.SellerStatsDto {
  SellerStats toDomain() => SellerStats(
    revenueTotal: revenueTotal,
    revenueThisMonth: revenueThisMonth,
    pendingBalance: pendingBalance,
    ordersToConfirm: ordersToConfirm,
    ordersShipping: ordersShipping,
    ordersCompleted: ordersCompleted,
    activeListings: activeListings,
    ratingAvg: ratingAvg,
  );
}

// ───────────────────────── catalog ─────────────────────────

extension CategoryDtoMapper on api.CategoryDto {
  Category toDomain() => Category(id: id, name: name, parentId: parentId);
}

extension BookDtoMapper on api.BookDto {
  Book toDomain() => Book(
    id: id,
    title: title,
    author: author,
    condition: conditionGrade.toDomain(),
    images: [
      for (final i in [
        ...images,
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
        BookImage(url: i.url, fromStaff: i.source == api.ImageSource.staff),
    ],
    publisher: publisher,
    publishYear: publishYear,
    isbn: isbn,
    language: language,
    pages: pages,
    categoryId: categoryId,
    categoryName: categoryName,
    description: description,
    weightGram: weightGram,
  );
}

extension BookDraftToApi on BookDraft {
  api.BookInput toRequest() => api.BookInput(
    title: title,
    author: author,
    conditionGrade: toApiEnum(api.ConditionGrade.values, condition),
    imageUrls: imageUrls,
    publisher: publisher,
    publishYear: publishYear,
    isbn: isbn,
    language: language,
    pages: pages,
    categoryId: categoryId,
    description: description,
    weightGram: weightGram,
  );
}

extension ListingDtoMapper on api.ListingDto {
  Listing toDomain() => Listing(
    id: id,
    book: book.toDomain(),
    shop: shop.toDomain(),
    price: price,
    stock: stock,
    status: _enum(ListingStatus.values, status, ListingStatus.hidden),
    createdAt: createdAt,
    rejectReason: rejectReason,
  );
}

extension ListingPageMapper on api.ListingPage {
  Paged<Listing> toDomain() => Paged(
    items: items.map((e) => e.toDomain()).toList(),
    page: page,
    size: size,
    total: total,
  );
}

extension ReviewDtoMapper on api.ReviewDto {
  Review toDomain() => Review(
    id: id,
    orderId: orderId,
    reviewerName: reviewerName,
    rating: rating,
    createdAt: createdAt,
    comment: comment,
  );
}

// ───────────────────────── commerce ─────────────────────────

extension CartDtoMapper on api.CartDto {
  Cart toDomain() => Cart(
    groups: [
      for (final g in groups)
        CartGroup(
          shop: g.shop.toDomain(),
          items: [
            for (final i in g.items)
              CartItem(
                id: i.id,
                listing: i.listing.toDomain(),
                quantity: i.quantity,
              ),
          ],
          subtotal: g.subtotal,
          shippingFee: g.shippingFee,
        ),
    ],
    subtotal: subtotal,
    shippingTotal: shippingTotal,
    total: total,
  );
}

extension OrderDtoMapper on api.OrderDto {
  Order toDomain() => Order(
    id: id,
    code: code,
    type: _enum(OrderType.values, orderType, OrderType.normal),
    status: status.toDomain(),
    items: [
      for (final i in items)
        OrderItem(
          id: i.id,
          title: i.titleSnapshot,
          unitPrice: i.unitPrice,
          quantity: i.quantity,
          listingId: i.listingId,
          lotId: i.lotId,
          imageUrl: i.imageUrl,
        ),
    ],
    subtotal: subtotal,
    shippingFee: shippingFee,
    buyerPremium: buyerPremium,
    depositApplied: depositApplied,
    total: total,
    createdAt: createdAt,
    history: [
      for (final h in history)
        OrderStatusChange(
          to: h.toStatus.toDomain(),
          from: h.fromStatus?.toDomain(),
          at: h.createdAt,
          note: h.note,
        ),
    ],
    canReview: canReview,
    shop: shop?.toDomain(),
    buyerName: buyerName,
    paymentMethod: paymentMethod == null
        ? null
        : _enum(PaymentMethod.values, paymentMethod!, PaymentMethod.cod),
    address: address?.toDomain(),
    pickupAtWarehouse: pickupAtWarehouse ?? false,
    trackingCode: trackingCode,
    paymentDeadline: paymentDeadline,
    confirmDeadline: confirmDeadline,
    complaintDeadline: complaintDeadline,
    cancelRequested: cancelRequested ?? false,
    review: review?.toDomain(),
    returnRequest: returnRequest == null
        ? null
        : ReturnRequest(
            id: returnRequest!.id,
            reason: returnRequest!.reason,
            imageUrls: returnRequest!.imageUrls,
            status: _enum(
              ReturnStatus.values,
              returnRequest!.status,
              ReturnStatus.pending,
            ),
            resolution: returnRequest!.resolution,
          ),
  );
}

extension OrderPageMapper on api.OrderPage {
  Paged<Order> toDomain() => Paged(
    items: items.map((e) => e.toDomain()).toList(),
    page: page,
    size: size,
    total: total,
  );
}

extension PaymentDtoMapper on api.PaymentDto {
  Payment toDomain() => Payment(
    id: id,
    amount: amount,
    status: _enum(PaymentStatus.values, status, PaymentStatus.pending),
    paymentUrl: paymentUrl,
    expiresAt: expiresAt,
  );
}

extension CheckoutResponseMapper on api.CheckoutResponse {
  CheckoutResult toDomain() => CheckoutResult(
    orders: orders.map((o) => o.toDomain()).toList(),
    payment: payment?.toDomain(),
  );
}

extension WalletDtoMapper on api.WalletDto {
  Wallet toDomain() => Wallet(available: availableBalance, held: heldBalance);
}

extension WalletTxnDtoMapper on api.WalletTransactionDto {
  WalletTxn toDomain() => WalletTxn(
    id: id,
    type: _enum(WalletTxnType.values, type, WalletTxnType.payment),
    amount: amount,
    balanceAfter: balanceAfter,
    createdAt: createdAt,
    note: note,
    refType: refType,
    refId: refId,
  );
}

extension WithdrawalDtoMapper on api.WithdrawalDto {
  Withdrawal toDomain() => Withdrawal(
    id: id,
    amount: amount,
    status: _enum(WithdrawalStatus.values, status, WithdrawalStatus.pending),
    createdAt: createdAt,
    userName: userName,
  );
}

extension NotificationDtoMapper on api.NotificationDto {
  AppNotification toDomain() => AppNotification(
    id: id,
    type: _enum(NotificationType.values, type, NotificationType.system),
    title: title,
    body: body,
    isRead: isRead,
    createdAt: createdAt,
    link: link,
  );
}

// ───────────────────────── consignment ─────────────────────────

extension InspectionDtoMapper on api.InspectionDto {
  Inspection toDomain() => Inspection(
    id: id,
    result: _enum(InspectionResult.values, result, InspectionResult.fail),
    checklist: InspectionChecklist(
      fullPages: checklist.fullPages,
      correctEdition: checklist.correctEdition,
      coverOk: checklist.coverOk,
      spineOk: checklist.spineOk,
      pagesOk: checklist.pagesOk,
      noMold: checklist.noMold,
      hasNotes: checklist.hasNotes,
      signature: _enum(
        SignatureStatus.values,
        checklist.signature,
        SignatureStatus.none,
      ),
    ),
    condition: conditionGrade.toDomain(),
    conditionReport: conditionReport,
    staffImageUrls: staffImageUrls,
    sellerDecision: _enum(
      SellerDecision.values,
      sellerDecision,
      SellerDecision.pending,
    ),
    createdAt: createdAt,
    estimateLow: estimateLow,
    estimateHigh: estimateHigh,
    proposedStart: proposedStart,
    proposedReserve: proposedReserve,
    counterReserve: counterReserve,
  );
}

extension InspectionDraftToApi on InspectionDraft {
  api.InspectionRequest toRequest() => api.InspectionRequest(
    result: toApiEnum(api.InspectionResult.values, result),
    checklist: api.InspectionChecklistDto(
      fullPages: checklist.fullPages,
      correctEdition: checklist.correctEdition,
      coverOk: checklist.coverOk,
      spineOk: checklist.spineOk,
      pagesOk: checklist.pagesOk,
      noMold: checklist.noMold,
      hasNotes: checklist.hasNotes,
      signature: toApiEnum(api.SignatureStatus.values, checklist.signature),
    ),
    conditionGrade: toApiEnum(api.ConditionGrade.values, condition),
    conditionReport: conditionReport,
    staffImageUrls: staffImageUrls,
    estimateLow: estimateLow,
    estimateHigh: estimateHigh,
    proposedStart: proposedStart,
    proposedReserve: proposedReserve,
  );
}

extension ConsignmentDtoMapper on api.ConsignmentDto {
  Consignment toDomain() => Consignment(
    id: id,
    sellerName: sellerName,
    book: book.toDomain(),
    expectedPrice: expectedPrice,
    story: story,
    status: _enum(
      ConsignmentStatus.values,
      status,
      ConsignmentStatus.submitted,
    ),
    createdAt: createdAt,
    sellerId: sellerId,
    rejectReason: rejectReason,
    approvedAt: approvedAt,
    appointmentAt: appointmentAt,
    appointmentCode: appointmentCode,
    appointmentExpiresAt: appointmentExpiresAt,
    receivedAt: receivedAt,
    warehouseCode: warehouseCode,
    inspection: inspection?.toDomain(),
    lotId: lotId,
    lotStatus: lotStatus?.toDomain(),
    hammerPrice: hammerPrice,
    payout: payout,
  );
}

extension WarehouseItemDtoMapper on api.WarehouseItemDto {
  WarehouseItem toDomain() => WarehouseItem(
    id: id,
    consignmentId: consignmentId,
    bookTitle: bookTitle,
    shelfCode: shelfCode,
    status: _enum(WarehouseStatus.values, status, WarehouseStatus.inStock),
    checkedInAt: checkedInAt,
    sellerName: sellerName,
    lotStatus: lotStatus?.toDomain(),
    checkedOutAt: checkedOutAt,
  );
}

// ───────────────────────── auction ─────────────────────────

extension AuctionSessionDtoMapper on api.AuctionSessionDto {
  AuctionSession toDomain() => AuctionSession(
    id: id,
    title: title,
    startAt: startAt,
    registrationDeadline: registrationDeadline,
    minParticipants: minParticipants,
    depositAmount: depositAmount,
    lotDurationSec: lotDurationSec,
    softCloseSec: softCloseSec,
    status: status.toDomain(),
    lotCount: lotCount,
    registeredCount: registeredCount,
    description: description,
    coverImageUrl: coverImageUrl,
    currentLotId: currentLotId,
    watcherCount: watcherCount ?? 0,
  );
}

extension AuctionSessionToApi on AuctionSession {
  api.SessionRequest toRequest() => api.SessionRequest(
    title: title,
    description: description,
    startAt: startAt,
    registrationDeadline: registrationDeadline,
    minParticipants: minParticipants,
    depositAmount: depositAmount,
    lotDurationSec: lotDurationSec,
    softCloseSec: softCloseSec,
  );
}

extension LotDtoMapper on api.LotDto {
  Lot toDomain() => Lot(
    id: id,
    sessionId: sessionId,
    lotNumber: lotNumber,
    book: book.toDomain(),
    estimateLow: estimateLow,
    estimateHigh: estimateHigh,
    startPrice: startPrice,
    currentPrice: currentPrice,
    bidCount: bidCount,
    status: status.toDomain(),
    watched: watched,
    story: story,
    conditionReport: conditionReport,
    signature: signature == null
        ? SignatureStatus.none
        : _enum(SignatureStatus.values, signature!, SignatureStatus.none),
    outcome: outcome == null
        ? null
        : _enum(LotOutcome.values, outcome!, LotOutcome.noBids),
    endsAt: endsAt,
    hammerPrice: hammerPrice,
    leadingPaddle: leadingPaddle,
  );
}

extension RegistrationDtoMapper on api.RegistrationDto {
  Registration toDomain() => Registration(
    id: id,
    sessionId: sessionId,
    sessionTitle: sessionTitle,
    paddleNumber: paddleNumber,
    depositAmount: depositAmount,
    bidLimit: bidLimit,
    committedAmount: committedAmount,
    status: _enum(
      RegistrationStatus.values,
      status,
      RegistrationStatus.pendingDeposit,
    ),
  );
}

extension BidDtoMapper on api.BidDto {
  Bid toDomain() => Bid(
    id: id,
    lotId: lotId,
    paddleNumber: paddleNumber,
    amount: amount,
    createdAt: createdAt,
    isAuto: isAuto,
  );
}

extension SessionStateDtoMapper on api.SessionStateDto {
  SessionState toDomain() => SessionState(
    session: session.toDomain(),
    lots: lots.map((l) => l.toDomain()).toList(),
    serverTime: serverTime,
    recentBids: recentBids.map((b) => b.toDomain()).toList(),
    currentLot: currentLot?.toDomain(),
    myRegistration: myRegistration?.toDomain(),
    viewerCount: viewerCount ?? 0,
  );
}

extension SessionResultDtoMapper on api.SessionResultDto {
  SessionResult toDomain() => SessionResult(
    session: session.toDomain(),
    results: [
      for (final r in results)
        LotResult(
          lotId: r.lotId,
          lotNumber: r.lotNumber,
          title: r.title,
          outcome: _enum(LotOutcome.values, r.outcome, LotOutcome.noBids),
          hammerPrice: r.hammerPrice,
          winnerPaddle: r.winnerPaddle,
          wonByMe: r.wonByMe ?? false,
        ),
    ],
  );
}

extension AuctionEventDtoMapper on api.AuctionEventDto {
  /// null nếu là sự kiện app chưa hiểu (backend thêm loại mới).
  AuctionEvent? toDomain() => switch (type) {
    api.AuctionEventDtoType.lotOpened when lot != null => LotOpened(
      serverTime,
      lot!.toDomain(),
    ),
    api.AuctionEventDtoType.bidPlaced when lot != null && bid != null =>
      BidPlaced(serverTime, lot!.toDomain(), bid!.toDomain()),
    api.AuctionEventDtoType.lotClosed when lot != null => LotClosed(
      serverTime,
      lot!.toDomain(),
    ),
    api.AuctionEventDtoType.sessionPaused => SessionPaused(serverTime),
    api.AuctionEventDtoType.sessionResumed => SessionResumed(
      serverTime,
      lot?.toDomain(),
    ),
    api.AuctionEventDtoType.sessionEnded => SessionEnded(serverTime),
    _ => null,
  };
}

// ───────────────────────── admin ─────────────────────────

extension SystemConfigDtoMapper on api.SystemConfigDto {
  SystemConfig toDomain() => SystemConfig(
    fixedPriceFeePercent: fixedPriceFeePercent,
    buyerPremiumPercent: buyerPremiumPercent,
    sellerCommissionPercent: sellerCommissionPercent,
    storageFeePerDay: storageFeePerDay,
    storageFreeDays: storageFreeDays,
    orderPaymentTimeoutMin: orderPaymentTimeoutMin,
    auctionPaymentTimeoutHours: auctionPaymentTimeoutHours,
    depositLimitMultiplier: depositLimitMultiplier,
    auctionBanDays: auctionBanDays,
    bidTiers: [
      for (final t in bidIncrementTiers) BidTier(t.fromPrice, t.increment),
    ],
  );
}

extension SystemConfigToApi on SystemConfig {
  api.SystemConfigDto toDto() => api.SystemConfigDto(
    fixedPriceFeePercent: fixedPriceFeePercent,
    buyerPremiumPercent: buyerPremiumPercent,
    sellerCommissionPercent: sellerCommissionPercent,
    storageFeePerDay: storageFeePerDay,
    storageFreeDays: storageFreeDays,
    orderPaymentTimeoutMin: orderPaymentTimeoutMin,
    auctionPaymentTimeoutHours: auctionPaymentTimeoutHours,
    depositLimitMultiplier: depositLimitMultiplier,
    auctionBanDays: auctionBanDays,
    bidIncrementTiers: [
      for (final t in bidTiers)
        api.BidIncrementTierDto(fromPrice: t.fromPrice, increment: t.increment),
    ],
  );
}

extension DashboardDtoMapper on api.DashboardDto {
  Dashboard toDomain() => Dashboard(
    revenueTotal: revenueTotal,
    platformFees: platformFees,
    orderCount: orderCount,
    lotSoldRate: lotSoldRate,
    activeUsers: activeUsers,
    pendingListings: pendingListings,
    pendingConsignments: pendingConsignments,
  );
}

// ───────────────────────── phiên đăng nhập ─────────────────────────

extension AuthResponseMapper on api.AuthResponse {
  (AuthTokens, AppUser) toDomain() => (
    AuthTokens(accessToken: accessToken, refreshToken: refreshToken),
    user.toDomain(),
  );
}
