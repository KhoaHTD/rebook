/// Chuyển đổi DTO (sinh từ openapi.yaml của backend) ↔ entity trong shared/domain.
/// Backend đổi tên trường → chỉ sửa file này; entity và UI giữ nguyên.
///
/// Quy ước: id backend là số nguyên, entity dùng String; tiền là số thập phân,
/// entity dùng int VND; mọi trường DTO đều nullable nên mapper luôn có giá trị mặc định.
library;

import 'package:book_marketplace/api/generated/export.dart' as api;
import 'package:book_marketplace/core/auth/auth_tokens.dart';
import 'package:book_marketplace/core/error/app_exception.dart';
import 'package:book_marketplace/shared/data/book_cover_assets.dart';
import 'package:book_marketplace/shared/domain/auction.dart';
import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/commerce.dart';
import 'package:book_marketplace/shared/domain/consignment.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/rules.dart';
import 'package:book_marketplace/shared/domain/user.dart';

// ───────────────────────── helpers ─────────────────────────

String _id(int? v) => v?.toString() ?? '';
int _n(num? v) => v?.round() ?? 0;
int? _nn(num? v) => v?.round();

/// Id trong app (String) → id backend (int). Id không phải số = không tồn tại.
int apiId(String id) =>
    int.tryParse(id) ?? (throw const ServerException(404, code: 'NOT_FOUND'));

DateTime _t(DateTime? v) => v ?? DateTime.fromMillisecondsSinceEpoch(0);

// ───────────────────────── enums ─────────────────────────

ConditionGrade conditionToDomain(api.ConditionGrade? g) => switch (g) {
  api.ConditionGrade.valueNew => ConditionGrade.brandNew,
  api.ConditionGrade.likeNew => ConditionGrade.likeNew,
  api.ConditionGrade.veryGood => ConditionGrade.veryGood,
  api.ConditionGrade.good => ConditionGrade.good,
  api.ConditionGrade.acceptable => ConditionGrade.acceptable,
  _ => ConditionGrade.unknown,
};

api.ConditionGrade conditionToApi(ConditionGrade g) => switch (g) {
  ConditionGrade.brandNew => api.ConditionGrade.valueNew,
  ConditionGrade.likeNew => api.ConditionGrade.likeNew,
  ConditionGrade.veryGood => api.ConditionGrade.veryGood,
  ConditionGrade.good => api.ConditionGrade.good,
  ConditionGrade.acceptable => api.ConditionGrade.acceptable,
  ConditionGrade.unknown => api.ConditionGrade.good,
};

OrderStatus orderStatusToDomain(api.OrderStatus? s) => switch (s) {
  api.OrderStatus.pendingPayment => OrderStatus.pendingPayment,
  api.OrderStatus.pendingConfirm => OrderStatus.pendingConfirm,
  api.OrderStatus.preparing => OrderStatus.preparing,
  api.OrderStatus.shipping => OrderStatus.shipping,
  api.OrderStatus.delivered => OrderStatus.delivered,
  api.OrderStatus.returnRequested => OrderStatus.returnRequested,
  api.OrderStatus.completed => OrderStatus.completed,
  api.OrderStatus.cancelled => OrderStatus.cancelled,
  api.OrderStatus.returned => OrderStatus.returned,
  api.OrderStatus.failedDelivery => OrderStatus.failedDelivery,
  _ => OrderStatus.pendingConfirm,
};

api.OrderStatus orderStatusToApi(OrderStatus s) => switch (s) {
  OrderStatus.pendingPayment => api.OrderStatus.pendingPayment,
  OrderStatus.pendingConfirm => api.OrderStatus.pendingConfirm,
  OrderStatus.preparing => api.OrderStatus.preparing,
  OrderStatus.shipping => api.OrderStatus.shipping,
  OrderStatus.delivered => api.OrderStatus.delivered,
  OrderStatus.returnRequested => api.OrderStatus.returnRequested,
  OrderStatus.completed => api.OrderStatus.completed,
  OrderStatus.cancelled => api.OrderStatus.cancelled,
  OrderStatus.returned => api.OrderStatus.returned,
  OrderStatus.failedDelivery => api.OrderStatus.failedDelivery,
};

ListingStatus listingStatusToDomain(api.ListingStatus? s) => switch (s) {
  api.ListingStatus.pendingReview => ListingStatus.pendingReview,
  api.ListingStatus.active => ListingStatus.active,
  api.ListingStatus.outOfStock => ListingStatus.outOfStock,
  api.ListingStatus.hidden => ListingStatus.hidden,
  api.ListingStatus.rejected => ListingStatus.rejected,
  _ => ListingStatus.hidden,
};

api.ListingStatus listingStatusToApi(ListingStatus s) => switch (s) {
  ListingStatus.pendingReview => api.ListingStatus.pendingReview,
  ListingStatus.active => api.ListingStatus.active,
  ListingStatus.outOfStock => api.ListingStatus.outOfStock,
  ListingStatus.hidden => api.ListingStatus.hidden,
  ListingStatus.rejected => api.ListingStatus.rejected,
};

/// Backend có thêm `open` (đang đấu) = `live`, `paid` / `converted` coi như đã xong.
LotStatus lotStatusToDomain(api.LotStatus? s) => switch (s) {
  api.LotStatus.ready => LotStatus.ready,
  api.LotStatus.scheduled => LotStatus.scheduled,
  api.LotStatus.open => LotStatus.live,
  api.LotStatus.sold => LotStatus.sold,
  api.LotStatus.paid => LotStatus.sold,
  api.LotStatus.unsold => LotStatus.unsold,
  api.LotStatus.completed => LotStatus.completed,
  api.LotStatus.converted => LotStatus.completed,
  api.LotStatus.cancelled => LotStatus.cancelled,
  api.LotStatus.returned => LotStatus.returned,
  _ => LotStatus.ready,
};

LotOutcome? lotOutcomeToDomain(api.LotCloseResult? r) => switch (r) {
  api.LotCloseResult.sold => LotOutcome.sold,
  api.LotCloseResult.reserveNotMet => LotOutcome.belowReserve,
  api.LotCloseResult.noBids => LotOutcome.noBids,
  api.LotCloseResult.cancelled => LotOutcome.cancelled,
  _ => null,
};

SessionStatus sessionStatusToDomain(api.SessionStatus? s) => switch (s) {
  api.SessionStatus.draft => SessionStatus.draft,
  api.SessionStatus.published => SessionStatus.published,
  api.SessionStatus.postponed => SessionStatus.postponed,
  api.SessionStatus.confirmed => SessionStatus.confirmed,
  api.SessionStatus.live => SessionStatus.live,
  api.SessionStatus.paused => SessionStatus.paused,
  api.SessionStatus.ended => SessionStatus.ended,
  api.SessionStatus.cancelled => SessionStatus.cancelled,
  _ => SessionStatus.published,
};

api.SessionStatus sessionStatusToApi(SessionStatus s) => switch (s) {
  SessionStatus.draft => api.SessionStatus.draft,
  SessionStatus.published => api.SessionStatus.published,
  SessionStatus.postponed => api.SessionStatus.postponed,
  SessionStatus.confirmed => api.SessionStatus.confirmed,
  SessionStatus.live => api.SessionStatus.live,
  SessionStatus.paused => api.SessionStatus.paused,
  SessionStatus.ended => api.SessionStatus.ended,
  SessionStatus.cancelled => api.SessionStatus.cancelled,
};

RegistrationStatus registrationStatusToDomain(api.RegistrationStatus? s) =>
    switch (s) {
      api.RegistrationStatus.pendingDeposit =>
        RegistrationStatus.pendingDeposit,
      api.RegistrationStatus.approved => RegistrationStatus.approved,
      api.RegistrationStatus.refunded => RegistrationStatus.refunded,
      api.RegistrationStatus.applied => RegistrationStatus.applied,
      api.RegistrationStatus.forfeited => RegistrationStatus.forfeited,
      _ => RegistrationStatus.pendingDeposit,
    };

PaymentMethod paymentMethodToDomain(api.PaymentMethod? m) => switch (m) {
  api.PaymentMethod.cod => PaymentMethod.cod,
  api.PaymentMethod.wallet => PaymentMethod.wallet,
  api.PaymentMethod.vnpay => PaymentMethod.vnpay,
  _ => PaymentMethod.cod,
};

api.PaymentMethod paymentMethodToApi(PaymentMethod m) => switch (m) {
  PaymentMethod.cod => api.PaymentMethod.cod,
  PaymentMethod.wallet => api.PaymentMethod.wallet,
  PaymentMethod.vnpay => api.PaymentMethod.vnpay,
};

PaymentStatus paymentStatusToDomain(api.PaymentStatus? s) => switch (s) {
  api.PaymentStatus.pending => PaymentStatus.pending,
  api.PaymentStatus.success => PaymentStatus.success,
  api.PaymentStatus.failed => PaymentStatus.failed,
  api.PaymentStatus.expired => PaymentStatus.expired,
  _ => PaymentStatus.pending,
};

WalletTxnType walletTxnTypeToDomain(api.WalletTxType? t) => switch (t) {
  api.WalletTxType.topUp => WalletTxnType.topUp,
  api.WalletTxType.payment => WalletTxnType.payment,
  api.WalletTxType.refund => WalletTxnType.refund,
  api.WalletTxType.depositHold => WalletTxnType.depositHold,
  api.WalletTxType.depositRelease => WalletTxnType.depositRelease,
  api.WalletTxType.depositForfeit => WalletTxnType.depositForfeit,
  api.WalletTxType.salePending => WalletTxnType.salePending,
  api.WalletTxType.saleRelease => WalletTxnType.saleRelease,
  api.WalletTxType.fee => WalletTxnType.fee,
  api.WalletTxType.withdraw => WalletTxnType.withdraw,
  _ => WalletTxnType.payment,
};

WithdrawalStatus withdrawalStatusToDomain(api.WithdrawStatus? s) => switch (s) {
  api.WithdrawStatus.pending => WithdrawalStatus.pending,
  api.WithdrawStatus.approved => WithdrawalStatus.completed,
  api.WithdrawStatus.rejected => WithdrawalStatus.rejected,
  _ => WithdrawalStatus.pending,
};

ReturnStatus returnStatusToDomain(api.ReturnStatus? s) => switch (s) {
  api.ReturnStatus.pending => ReturnStatus.pending,
  api.ReturnStatus.approved => ReturnStatus.accepted,
  api.ReturnStatus.disputed => ReturnStatus.escalated,
  api.ReturnStatus.rejected => ReturnStatus.rejected,
  _ => ReturnStatus.pending,
};

/// Backend: `approved` / `rejected` = kết quả duyệt sơ bộ; `awaitingSeller` = đã kiểm định, chờ người bán.
ConsignmentStatus consignmentStatusToDomain(api.ConsignmentStatus? s) =>
    switch (s) {
      api.ConsignmentStatus.submitted => ConsignmentStatus.submitted,
      api.ConsignmentStatus.approved => ConsignmentStatus.preApproved,
      api.ConsignmentStatus.rejected => ConsignmentStatus.preRejected,
      api.ConsignmentStatus.appointmentBooked =>
        ConsignmentStatus.appointmentBooked,
      api.ConsignmentStatus.expired => ConsignmentStatus.expired,
      api.ConsignmentStatus.received => ConsignmentStatus.received,
      api.ConsignmentStatus.inspectionFailed =>
        ConsignmentStatus.inspectionFailed,
      api.ConsignmentStatus.awaitingSeller => ConsignmentStatus.inspected,
      api.ConsignmentStatus.accepted => ConsignmentStatus.accepted,
      api.ConsignmentStatus.withdrawn => ConsignmentStatus.withdrawn,
      api.ConsignmentStatus.returned => ConsignmentStatus.returned,
      _ => ConsignmentStatus.submitted,
    };

api.ConsignmentStatus consignmentStatusToApi(ConsignmentStatus s) =>
    switch (s) {
      ConsignmentStatus.submitted => api.ConsignmentStatus.submitted,
      ConsignmentStatus.preApproved => api.ConsignmentStatus.approved,
      ConsignmentStatus.preRejected => api.ConsignmentStatus.rejected,
      ConsignmentStatus.appointmentBooked =>
        api.ConsignmentStatus.appointmentBooked,
      ConsignmentStatus.expired => api.ConsignmentStatus.expired,
      ConsignmentStatus.received => api.ConsignmentStatus.received,
      ConsignmentStatus.inspected => api.ConsignmentStatus.awaitingSeller,
      ConsignmentStatus.inspectionFailed =>
        api.ConsignmentStatus.inspectionFailed,
      ConsignmentStatus.accepted => api.ConsignmentStatus.accepted,
      ConsignmentStatus.withdrawn => api.ConsignmentStatus.withdrawn,
      ConsignmentStatus.returned => api.ConsignmentStatus.returned,
    };

WarehouseStatus warehouseStatusToDomain(api.WarehouseStatus? s) => switch (s) {
  api.WarehouseStatus.inStock => WarehouseStatus.inStock,
  api.WarehouseStatus.reserved => WarehouseStatus.reserved,
  api.WarehouseStatus.shipped => WarehouseStatus.shipped,
  api.WarehouseStatus.returned => WarehouseStatus.returned,
  _ => WarehouseStatus.inStock,
};

api.WarehouseStatus warehouseStatusToApi(WarehouseStatus s) => switch (s) {
  WarehouseStatus.inStock => api.WarehouseStatus.inStock,
  WarehouseStatus.reserved => api.WarehouseStatus.reserved,
  WarehouseStatus.shipped => api.WarehouseStatus.shipped,
  WarehouseStatus.returned => api.WarehouseStatus.returned,
};

SellerDecision sellerDecisionToDomain(api.SellerDecision? d) => switch (d) {
  api.SellerDecision.pending => SellerDecision.pending,
  api.SellerDecision.accepted => SellerDecision.accept,
  api.SellerDecision.counter => SellerDecision.counter,
  api.SellerDecision.withdrawn => SellerDecision.withdraw,
  _ => SellerDecision.pending,
};

api.UnsoldAction unsoldActionToApi(UnsoldChoice c) => switch (c) {
  UnsoldChoice.nextSession => api.UnsoldAction.relist,
  UnsoldChoice.fixedPrice => api.UnsoldAction.convertToListing,
  UnsoldChoice.returnToSeller => api.UnsoldAction.valueReturn,
};

NotificationType notificationTypeToDomain(String? t) => switch (t) {
  'ORDER' => NotificationType.order,
  'AUCTION_REMINDER' => NotificationType.auctionReminder,
  'AUCTION_OUTBID' => NotificationType.outbid,
  'AUCTION_WON' => NotificationType.auctionWon,
  'AUCTION' => NotificationType.auctionResult,
  'CONSIGNMENT' => NotificationType.consignment,
  'WALLET' => NotificationType.wallet,
  _ => NotificationType.system,
};

// ───────────────────────── users ─────────────────────────

extension UserResponseMapper on api.UserResponse {
  AppUser toDomain() => AppUser(
    id: _id(id),
    email: email ?? '',
    fullName: fullName ?? '',
    role: switch (role) {
      api.Role.staff => UserRole.staff,
      api.Role.admin => UserRole.admin,
      _ => UserRole.user,
    },
    phoneVerified: phoneVerified ?? false,
    hasShop: shopId != null,
    phone: phone,
    avatarUrl: avatarUrl,
    locked: status == api.UserStatus.locked,
    auctionBannedUntil: auctionBannedUntil,
    createdAt: createdAt,
  );
}

extension AddressResponseMapper on api.AddressResponse {
  Address toDomain() => Address(
    id: _id(id),
    receiver: receiverName ?? '',
    phone: phone ?? '',
    province: province ?? '',
    district: district ?? '',
    ward: ward ?? '',
    detail: detail ?? '',
    isDefault: isDefault ?? false,
  );
}

/// Địa chỉ chụp lại trong đơn hàng (`Map` không id).
Address addressFromSnapshot(Map<String, dynamic> m) => Address(
  id: '',
  receiver: '${m['receiverName'] ?? ''}',
  phone: '${m['phone'] ?? ''}',
  province: '${m['province'] ?? ''}',
  district: '${m['district'] ?? ''}',
  ward: '${m['ward'] ?? ''}',
  detail: '${m['detail'] ?? ''}',
  isDefault: false,
);

extension AddressToApi on Address {
  api.AddressRequest toRequest() => api.AddressRequest(
    receiverName: receiver,
    phone: phone,
    province: province,
    district: district,
    ward: ward,
    detail: detail,
    isDefault: isDefault,
  );
}

extension ShopBriefMapper on api.ShopBrief {
  ShopSummary toDomain() => ShopSummary(
    id: _id(id),
    name: name ?? '',
    ratingAvg: ratingAvg?.toDouble() ?? 0,
    ratingCount: ratingCount ?? 0,
  );
}

extension ShopResponseMapper on api.ShopResponse {
  ShopSummary toSummary() => ShopSummary(
    id: _id(id),
    name: name ?? '',
    ratingAvg: ratingAvg?.toDouble() ?? 0,
    ratingCount: ratingCount ?? 0,
  );

  Shop toDomain() => Shop(
    id: _id(id),
    userId: _id(ownerId),
    name: name ?? '',
    pickupAddress: pickupAddress ?? '',
    ratingAvg: ratingAvg?.toDouble() ?? 0,
    ratingCount: ratingCount ?? 0,
    createdAt: _t(createdAt),
    description: description,
  );
}

extension ShopDraftToApi on ShopDraft {
  api.ShopRequest toRequest() => api.ShopRequest(
    name: name,
    description: description,
    pickupAddress: pickupAddress,
    // Backend cần tỉnh lấy hàng riêng: lấy đoạn cuối của địa chỉ "…, quận, tỉnh".
    pickupProvince: pickupAddress.split(',').last.trim(),
    bankName: bankName,
    bankAccountNumber: bankAccount,
    bankAccountHolder: bankHolder,
  );
}

// ───────────────────────── catalog ─────────────────────────

/// Cây danh mục của backend → danh sách phẳng (kèm parentId).
List<Category> flattenCategories(List<api.CategoryResponse> tree) => [
  for (final c in tree) ...[
    Category(
      id: _id(c.id),
      name: c.name ?? '',
      parentId: c.parentId == null ? null : _id(c.parentId),
    ),
    ...flattenCategories(c.children ?? const []),
  ],
];

extension BookResponseMapper on api.BookResponse {
  Book toDomain() {
    final urls = <BookImage>[
      for (final i in images ?? const <api.ImageResponse>[])
        if (i.url != null)
          BookImage(url: i.url!, fromStaff: i.source == api.ImageSource.staff),
    ];
    if (urls.isEmpty && coverUrl != null) urls.add(BookImage(url: coverUrl!));
    return Book(
      id: _id(id),
      title: title ?? '',
      author: author ?? '',
      condition: conditionToDomain(conditionGrade),
      images: _bundledOr(title, urls),
      publisher: publisher,
      publishYear: publishYear,
      isbn: isbn,
      language: language,
      pages: pages,
      categoryId: categoryId == null ? null : _id(categoryId),
      description: description,
      weightGram: weightGram,
    );
  }
}

extension BookDraftToApi on BookDraft {
  api.BookRequest toRequest() => api.BookRequest(
    title: title,
    author: author,
    conditionGrade: conditionToApi(condition),
    imageUrls: imageUrls,
    publisher: publisher,
    publishYear: publishYear,
    isbn: isbn,
    language: language,
    pages: pages,
    categoryId: int.tryParse(categoryId ?? '') ?? 1,
    description: description,
    weightGram: weightGram ?? 300,
  );
}

extension ListingDetailMapper on api.ListingDetail {
  Listing toDomain() => Listing(
    id: _id(id),
    book: book?.toDomain() ?? _emptyBook(_id(id)),
    shop:
        shop?.toDomain() ??
        const ShopSummary(id: '', name: '', ratingAvg: 0, ratingCount: 0),
    price: _n(price),
    stock: stock ?? 0,
    status: listingStatusToDomain(status),
    createdAt: _t(createdAt),
    rejectReason: rejectReason,
  );
}

extension ListingSummaryMapper on api.ListingSummary {
  /// Bản tóm tắt không có id sách: dùng id tin đăng thay thế.
  Listing toDomain() => Listing(
    id: _id(id),
    book: Book(
      id: _id(id),
      title: title ?? '',
      author: author ?? '',
      condition: conditionToDomain(conditionGrade),
      images: _cover(title, coverUrl),
    ),
    shop:
        shop?.toDomain() ??
        const ShopSummary(id: '', name: '', ratingAvg: 0, ratingCount: 0),
    price: _n(price),
    stock: stock ?? 0,
    status: listingStatusToDomain(status),
    createdAt: _t(createdAt),
  );
}

Book _emptyBook(String id) =>
    Book(id: id, title: '', author: '', condition: ConditionGrade.unknown);

Paged<T> pagedOf<T, S>({
  required List<S>? items,
  required int? page,
  required int? size,
  required int? totalItems,
  required T Function(S) map,
}) => Paged(
  items: [for (final e in items ?? <S>[]) map(e)],
  page: page ?? 0,
  size: size ?? 20,
  total: totalItems ?? 0,
);

extension ReviewResponseMapper on api.ReviewResponse {
  Review toDomain() => Review(
    id: _id(id),
    orderId: _id(orderId),
    reviewerName: reviewerName ?? '',
    rating: rating ?? 0,
    createdAt: _t(createdAt),
    comment: comment,
  );
}

// ───────────────────────── commerce ─────────────────────────

/// Giỏ hàng. Id mục giỏ = id tin đăng (backend khoá giỏ theo tin đăng).
/// [quote] = báo giá ship khi đã chọn địa chỉ nhận hàng.
Cart cartToDomain(api.CartResponse cart, {api.CheckoutPreview? quote}) {
  final fees = {
    for (final s in quote?.shops ?? const <api.ShopQuote>[])
      s.shopId: _n(s.shippingFee),
  };
  final groups = [
    for (final g in cart.shops ?? const <api.CartShopGroup>[])
      CartGroup(
        shop: ShopSummary(
          id: _id(g.shopId),
          name: g.shopName ?? '',
          ratingAvg: 0,
          ratingCount: 0,
        ),
        items: [
          for (final l in g.items ?? const <api.CartLine>[])
            CartItem(
              id: _id(l.listingId),
              quantity: l.quantity ?? 1,
              listing: Listing(
                id: _id(l.listingId),
                book: Book(
                  id: _id(l.listingId),
                  title: l.title ?? '',
                  author: l.author ?? '',
                  condition: ConditionGrade.unknown,
                  images: _cover(l.title, l.coverUrl),
                ),
                shop: ShopSummary(
                  id: _id(g.shopId),
                  name: g.shopName ?? '',
                  ratingAvg: 0,
                  ratingCount: 0,
                ),
                price: _n(l.price),
                stock: l.stock ?? 0,
                status: (l.available ?? true)
                    ? ListingStatus.active
                    : ListingStatus.outOfStock,
                createdAt: DateTime.now(),
              ),
            ),
        ],
        subtotal: _n(g.subtotal),
        shippingFee: fees[g.shopId] ?? 0,
      ),
  ];
  final subtotal = _n(cart.subtotal);
  final shipping = groups.fold(0, (n, g) => n + g.shippingFee);
  return Cart(
    groups: groups,
    subtotal: subtotal,
    shippingTotal: shipping,
    total: subtotal + shipping,
  );
}

extension OrderItemMapper on api.OrderItemResponse {
  OrderItem toDomain() => OrderItem(
    id: _id(id),
    title: title ?? '',
    unitPrice: _n(unitPrice),
    quantity: quantity ?? 1,
    listingId: listingId == null ? null : _id(listingId),
    lotId: lotId == null ? null : _id(lotId),
    imageUrl: imageUrl,
  );
}

extension ReturnResponseMapper on api.ReturnResponse {
  ReturnRequest toDomain() => ReturnRequest(
    id: _id(id),
    reason: description?.isNotEmpty == true
        ? description!
        : (reason?.name ?? ''),
    imageUrls: images ?? const [],
    status: returnStatusToDomain(status),
    resolution: resolution,
  );
}

extension OrderDetailMapper on api.OrderDetail {
  Order toDomain() => Order(
    id: _id(id),
    code: code ?? '',
    type: orderType == api.OrderType.auction
        ? OrderType.auction
        : OrderType.normal,
    status: orderStatusToDomain(status),
    items: [
      for (final i in items ?? const <api.OrderItemResponse>[]) i.toDomain(),
    ],
    subtotal: _n(subtotal),
    shippingFee: _n(shippingFee),
    buyerPremium: _n(buyerPremium),
    depositApplied: _n(depositApplied),
    total: _n(total),
    createdAt: _t(createdAt),
    history: [
      for (final h in history ?? const <api.HistoryResponse>[])
        OrderStatusChange(
          to: orderStatusToDomain(h.toStatus),
          from: h.fromStatus == null ? null : orderStatusToDomain(h.fromStatus),
          at: _t(h.createdAt),
          note: h.note,
        ),
    ],
    canReview: canReview ?? false,
    shop: shopId == null
        ? null
        : ShopSummary(
            id: _id(shopId),
            name: shopName ?? '',
            ratingAvg: 0,
            ratingCount: 0,
          ),
    paymentMethod: paymentMethod == null
        ? null
        : paymentMethodToDomain(paymentMethod),
    address: address == null ? null : addressFromSnapshot(address!),
    pickupAtWarehouse: pickupAtWarehouse ?? false,
    trackingCode: trackingCode,
    paymentDeadline: paymentDueAt,
    confirmDeadline: confirmDueAt,
    cancelRequested: cancelRequested ?? false,
    returnRequest: returnRequest?.toDomain(),
  );
}

extension OrderSummaryMapper on api.OrderSummary {
  /// Bản tóm tắt chỉ có sách đầu tiên: dựng một dòng hàng đại diện cho cả đơn.
  Order toDomain() => Order(
    id: _id(id),
    code: code ?? '',
    type: orderType == api.OrderType.auction
        ? OrderType.auction
        : OrderType.normal,
    status: orderStatusToDomain(status),
    items: [
      OrderItem(
        id: '0',
        title: firstItemTitle ?? '',
        unitPrice: _n(total),
        quantity: itemCount ?? 1,
        imageUrl: coverUrl,
      ),
    ],
    subtotal: _n(total),
    shippingFee: 0,
    buyerPremium: 0,
    depositApplied: 0,
    total: _n(total),
    createdAt: _t(createdAt),
    history: const [],
    canReview: false,
    shop: shopId == null
        ? null
        : ShopSummary(
            id: _id(shopId),
            name: shopName ?? '',
            ratingAvg: 0,
            ratingCount: 0,
          ),
    paymentMethod: paymentMethod == null
        ? null
        : paymentMethodToDomain(paymentMethod),
    paymentDeadline: paymentDueAt,
    cancelRequested: cancelRequested ?? false,
  );
}

extension PaymentResponseMapper on api.PaymentResponse {
  /// Id thanh toán trong app = mã thanh toán (`code`), vì API tra cứu theo mã.
  Payment toDomain() => Payment(
    id: code ?? _id(id),
    amount: _n(amount),
    status: paymentStatusToDomain(status),
    paymentUrl: paymentUrl,
    expiresAt: expiresAt,
  );
}

extension WalletResponseMapper on api.WalletResponse {
  Wallet toDomain() =>
      Wallet(available: _n(availableBalance), held: _n(heldBalance));
}

extension TransactionResponseMapper on api.TransactionResponse {
  WalletTxn toDomain() => WalletTxn(
    id: _id(id),
    type: walletTxnTypeToDomain(type),
    amount: _n(availableChange) != 0 ? _n(availableChange) : _n(heldChange),
    balanceAfter: _n(availableAfter),
    createdAt: _t(createdAt),
    note: note,
    refType: refType,
    refId: refId == null ? null : _id(refId),
  );
}

extension WithdrawResponseMapper on api.WithdrawResponse {
  Withdrawal toDomain() => Withdrawal(
    id: _id(id),
    amount: _n(amount),
    status: withdrawalStatusToDomain(status),
    createdAt: _t(createdAt),
    userName: accountHolder,
  );
}

extension NotificationResponseMapper on api.NotificationResponse {
  AppNotification toDomain() => AppNotification(
    id: _id(id),
    type: notificationTypeToDomain(type),
    title: title ?? '',
    body: body ?? '',
    isRead: read ?? false,
    createdAt: _t(createdAt),
  );
}

// ───────────────────────── consignment ─────────────────────────

InspectionChecklist checklistFromMap(Map<String, dynamic>? m) {
  bool b(String k, {required bool or}) => m?[k] is bool ? m![k] as bool : or;
  return InspectionChecklist(
    fullPages: b('fullPages', or: true),
    correctEdition: b('correctEdition', or: true),
    coverOk: b('coverOk', or: true),
    spineOk: b('spineOk', or: true),
    pagesOk: b('pagesOk', or: true),
    noMold: b('noMold', or: true),
    hasNotes: b('hasNotes', or: false),
    signature:
        SignatureStatus.values
            .where((s) => s.name == m?['signature'])
            .firstOrNull ??
        SignatureStatus.none,
  );
}

Map<String, dynamic> checklistToMap(InspectionChecklist c) => {
  'fullPages': c.fullPages,
  'correctEdition': c.correctEdition,
  'coverOk': c.coverOk,
  'spineOk': c.spineOk,
  'pagesOk': c.pagesOk,
  'noMold': c.noMold,
  'hasNotes': c.hasNotes,
  'signature': c.signature.name,
};

extension InspectionResponseMapper on api.InspectionResponse {
  Inspection toDomain() => Inspection(
    id: _id(id),
    result: result == api.InspectionResult.pass
        ? InspectionResult.pass
        : InspectionResult.fail,
    checklist: checklistFromMap(checklist),
    condition: conditionToDomain(conditionGrade),
    conditionReport: conditionReport ?? '',
    staffImageUrls: const [],
    sellerDecision: sellerDecisionToDomain(sellerDecision),
    createdAt: _t(createdAt),
    estimateLow: _nn(estimateLow),
    estimateHigh: _nn(estimateHigh),
    proposedStart: _nn(proposedStart),
    proposedReserve: _nn(proposedReserve),
    counterReserve: _nn(sellerCounterReserve),
  );
}

extension InspectionDraftToApi on InspectionDraft {
  api.InspectionRequest toRequest() => api.InspectionRequest(
    result: result == InspectionResult.pass
        ? api.InspectionResult.pass
        : api.InspectionResult.fail,
    checklist: checklistToMap(checklist),
    conditionGrade: conditionToApi(condition),
    conditionReport: conditionReport,
    photoUrls: staffImageUrls,
    estimateLow: estimateLow,
    estimateHigh: estimateHigh,
    proposedStart: proposedStart,
    proposedReserve: proposedReserve,
  );
}

extension ConsignmentResponseMapper on api.ConsignmentResponse {
  Consignment toDomain() => Consignment(
    id: _id(id),
    sellerName: sellerName ?? '',
    book: book?.toDomain() ?? _emptyBook(''),
    expectedPrice: _n(expectedPrice),
    story: provenance ?? '',
    status: consignmentStatusToDomain(status),
    createdAt: _t(createdAt),
    sellerId: sellerId == null ? null : _id(sellerId),
    rejectReason: reviewNote,
    approvedAt: approvedAt,
    appointmentAt: appointmentAt,
    appointmentCode: appointmentCode,
    receivedAt: receivedAt,
    warehouseCode: warehouse?.code,
    inspection: inspection?.toDomain(),
    lotId: lot?.id == null ? null : _id(lot!.id),
    lotStatus: lot?.status == null ? null : lotStatusToDomain(lot!.status),
    hammerPrice: _nn(lot?.hammerPrice),
  );
}

extension WarehouseResponseMapper on api.WarehouseResponse {
  WarehouseItem toDomain() => WarehouseItem(
    id: _id(id),
    consignmentId: _id(consignmentId),
    bookTitle: bookTitle ?? '',
    shelfCode: shelfCode ?? '',
    status: warehouseStatusToDomain(status),
    checkedInAt: _t(checkedInAt),
    checkedOutAt: checkedOutAt,
  );
}

// ───────────────────────── auction ─────────────────────────

extension SessionSummaryMapper on api.SessionSummary {
  /// [detail]: thời lượng lô / gia hạn chỉ có ở `SessionDetail`.
  AuctionSession toDomain({int lotDurationSec = 60, int softCloseSec = 15}) =>
      AuctionSession(
        id: _id(id),
        title: title ?? '',
        startAt: _t(startAt),
        registrationDeadline: _t(registrationDeadline),
        minParticipants: minParticipants ?? 1,
        depositAmount: _n(depositAmount),
        lotDurationSec: lotDurationSec,
        softCloseSec: softCloseSec,
        status: sessionStatusToDomain(status),
        lotCount: lotCount ?? 0,
        registeredCount: registeredCount ?? 0,
        description: description,
        coverImageUrl: coverUrl,
      );
}

extension AuctionSessionToApi on AuctionSession {
  api.SessionRequest toRequest() => api.SessionRequest(
    title: title,
    description: description,
    coverUrl: coverImageUrl,
    startAt: startAt.toUtc(),
    registrationDeadline: registrationDeadline.toUtc(),
    minParticipants: minParticipants,
    depositAmount: depositAmount,
    lotDurationSec: lotDurationSec,
    softCloseSec: softCloseSec,
  );
}

extension SessionDetailMapper on api.SessionDetail {
  AuctionSession sessionToDomain() =>
      (session ?? const api.SessionSummary()).toDomain(
        lotDurationSec: lotDurationSec ?? 60,
        softCloseSec: softCloseSec ?? 15,
      );

  List<Lot> lotsToDomain() => [
    for (final l in lots ?? const <api.LotPublic>[]) l.toDomain(),
  ];
}

extension LotPublicMapper on api.LotPublic {
  Lot toDomain({
    Book? book,
    String? story,
    String? conditionReport,
    SignatureStatus? signature,
  }) => Lot(
    id: _id(id),
    sessionId: _id(sessionId),
    lotNumber: lotNumber ?? 0,
    book:
        book ??
        Book(
          id: _id(id),
          title: title ?? '',
          author: author ?? '',
          condition: conditionToDomain(conditionGrade),
          images: _cover(title, coverUrl),
        ),
    estimateLow: _n(estimateLow),
    estimateHigh: _n(estimateHigh),
    startPrice: _n(startPrice),
    currentPrice: _n(currentPrice ?? startPrice),
    bidCount: bidCount ?? 0,
    status: lotStatusToDomain(status),
    watched: watching ?? false,
    story: story,
    conditionReport: conditionReport,
    signature: signature ?? SignatureStatus.none,
    outcome: lotOutcomeToDomain(closeResult),
    endsAt: endsAt,
    hammerPrice: _nn(hammerPrice),
    leadingPaddle: winnerPaddle,
  );
}

extension LotDetailMapper on api.LotDetail {
  Lot toDomain() {
    final pub = lot ?? const api.LotPublic();
    final sig = checklist?['signature'];
    return pub.toDomain(
      book: book?.toDomain(),
      story: provenance,
      conditionReport: conditionReport,
      signature: SignatureStatus.values.where((s) => s.name == sig).firstOrNull,
    );
  }
}

/// Lô đang đấu (`LotLive`) → Lot. [base] = lô cùng id đã tải trước đó
/// (giữ sách, ước giá, kể chuyện mà `LotLive` không mang theo).
Lot lotLiveToDomain(api.LotLive l, {Lot? base, String sessionId = ''}) {
  final start = _n(l.startPrice);
  final bidCount = l.bidCount ?? 0;
  final closed = l.closeResult != null;
  return Lot(
    id: _id(l.id),
    sessionId: base?.sessionId ?? sessionId,
    lotNumber: l.lotNumber ?? base?.lotNumber ?? 0,
    book:
        base?.book ??
        Book(
          id: _id(l.id),
          title: l.title ?? '',
          author: '',
          condition: ConditionGrade.unknown,
          images: _cover(l.title, l.coverUrl),
        ),
    estimateLow: base?.estimateLow ?? 0,
    estimateHigh: base?.estimateHigh ?? 0,
    startPrice: start,
    currentPrice: bidCount == 0 ? start : _n(l.currentPrice),
    bidCount: bidCount,
    status: lotStatusToDomain(l.status),
    watched: base?.watched ?? false,
    story: base?.story,
    conditionReport: base?.conditionReport,
    signature: base?.signature ?? SignatureStatus.none,
    outcome: lotOutcomeToDomain(l.closeResult),
    endsAt: l.endsAt,
    hammerPrice: closed ? _nn(l.hammerPrice) : null,
    leadingPaddle: l.leadingPaddle,
  );
}

extension RegistrationResponseMapper on api.RegistrationResponse {
  Registration toDomain({String sessionTitle = ''}) => Registration(
    id: _id(id),
    sessionId: _id(sessionId),
    sessionTitle: sessionTitle,
    paddleNumber: paddle ?? '',
    depositAmount: _n(depositAmount),
    bidLimit: _n(bidLimit),
    committedAmount: _n(committed),
    status: registrationStatusToDomain(status),
  );
}

/// Lịch sử trả giá trong `LotLive.recentBids` (mới nhất đứng đầu).
List<Bid> bidsToDomain(api.LotLive lot) {
  final views = lot.recentBids ?? const <api.BidView>[];
  final total = lot.bidCount ?? views.length;
  return [
    for (var i = 0; i < views.length; i++)
      Bid(
        id: '${lot.id}-${total - i}',
        lotId: _id(lot.id),
        paddleNumber: views[i].paddle ?? '',
        amount: _n(views[i].amount),
        createdAt: _t(views[i].at),
        isAuto: views[i].auto ?? false,
      ),
  ];
}

/// Sự kiện WebSocket → sự kiện domain; null nếu app chưa hiểu loại sự kiện đó.
AuctionEvent? auctionEventToDomain(
  api.AuctionEvent e, {
  Lot? Function(int id)? baseLot,
}) {
  final at = e.serverTime ?? DateTime.now();
  final live = e.lot;
  Lot? lot() => live == null
      ? null
      : lotLiveToDomain(
          live,
          base: live.id == null ? null : baseLot?.call(live.id!),
          sessionId: _id(e.sessionId),
        );
  switch (e.type) {
    case 'LOT_OPENED':
      final l = lot();
      return l == null ? null : LotOpened(at, l);
    case 'BID_PLACED':
      final l = lot();
      final bids = live == null ? const <Bid>[] : bidsToDomain(live);
      return l == null || bids.isEmpty ? null : BidPlaced(at, l, bids.first);
    case 'LOT_CLOSED':
      final l = lot();
      return l == null ? null : LotClosed(at, l);
    case 'SESSION_PAUSED':
      return SessionPaused(at);
    case 'SESSION_RESUMED':
      return SessionResumed(at, lot());
    case 'SESSION_ENDED':
    case 'SESSION_CANCELLED':
      return SessionEnded(at);
    default:
      return null;
  }
}

// ───────────────────────── admin ─────────────────────────

/// Khoá cấu hình của backend dùng trong màn quản trị.
abstract final class ConfigKeys {
  static const fixedPriceFee = 'fee.fixed_price_percent';
  static const buyerPremium = 'fee.buyer_premium_percent';
  static const sellerCommission = 'fee.seller_commission_percent';
  static const storagePerDay = 'fee.storage_per_day';
  static const storageFreeDays = 'fee.storage_free_days';
  static const paymentTimeoutMin = 'order.payment_timeout_minutes';
  static const auctionPaymentHours = 'auction.payment_hours';
  static const bidLimitMultiplier = 'auction.bid_limit_multiplier';
  static const banDays = 'auction.ban_days';
  static const bidTiers = 'auction.bid_increment_tiers';
}

SystemConfig systemConfigFromList(List<api.SystemConfig> list) {
  final m = {for (final c in list) c.key ?? '': c.value ?? ''};
  double d(String k, double or) => double.tryParse(m[k] ?? '') ?? or;
  int i(String k, int or) => int.tryParse(m[k] ?? '') ?? or;
  final tiers = <BidTier>[
    for (final part in (m[ConfigKeys.bidTiers] ?? '').split(','))
      if (part.contains(':'))
        BidTier(
          int.tryParse(part.split(':').first.trim()) ?? 0,
          int.tryParse(part.split(':').last.trim()) ?? 0,
        ),
  ];
  return SystemConfig(
    fixedPriceFeePercent: d(ConfigKeys.fixedPriceFee, 5),
    buyerPremiumPercent: d(ConfigKeys.buyerPremium, 10),
    sellerCommissionPercent: d(ConfigKeys.sellerCommission, 15),
    storageFeePerDay: i(ConfigKeys.storagePerDay, 5000),
    storageFreeDays: i(ConfigKeys.storageFreeDays, 14),
    orderPaymentTimeoutMin: i(ConfigKeys.paymentTimeoutMin, 15),
    auctionPaymentTimeoutHours: i(ConfigKeys.auctionPaymentHours, 48),
    depositLimitMultiplier: i(ConfigKeys.bidLimitMultiplier, 10),
    auctionBanDays: i(ConfigKeys.banDays, 90),
    bidTiers: tiers.isEmpty ? defaultBidTiers : tiers,
  );
}

/// Cặp (khoá, giá trị) của từng trường cấu hình, để gửi `PUT /admin/configs/{key}`.
Map<String, String> systemConfigToValues(SystemConfig c) => {
  ConfigKeys.fixedPriceFee: '${c.fixedPriceFeePercent}',
  ConfigKeys.buyerPremium: '${c.buyerPremiumPercent}',
  ConfigKeys.sellerCommission: '${c.sellerCommissionPercent}',
  ConfigKeys.storagePerDay: '${c.storageFeePerDay}',
  ConfigKeys.storageFreeDays: '${c.storageFreeDays}',
  ConfigKeys.paymentTimeoutMin: '${c.orderPaymentTimeoutMin}',
  ConfigKeys.auctionPaymentHours: '${c.auctionPaymentTimeoutHours}',
  ConfigKeys.bidLimitMultiplier: '${c.depositLimitMultiplier}',
  ConfigKeys.banDays: '${c.auctionBanDays}',
  ConfigKeys.bidTiers: c.bidTiers
      .map((t) => '${t.fromPrice}:${t.increment}')
      .join(','),
};

extension DashboardResponseMapper on api.DashboardResponse {
  /// Backend không trả số người dùng và số ký gửi chờ sơ duyệt: repository tự đếm rồi truyền vào.
  /// `lotSellThroughRate` của backend là phần trăm 0–100, entity dùng 0–1.
  Dashboard toDomain({int users = 0, int pendingConsignments = 0}) => Dashboard(
    revenueTotal: _n(revenueThisMonth),
    platformFees: _n(platformBalance),
    orderCount: ordersThisMonth ?? 0,
    lotSoldRate: (lotSellThroughRate ?? 0).toDouble() / 100,
    activeUsers: users,
    pendingListings: pendingListings ?? 0,
    pendingConsignments: pendingConsignments,
  );
}

// ───────────────────────── phiên đăng nhập ─────────────────────────

extension AuthResponseMapper on api.AuthResponse {
  (AuthTokens, AppUser) toDomain() => (
    AuthTokens(
      accessToken: accessToken ?? '',
      refreshToken: refreshToken ?? '',
    ),
    (user ?? const api.UserResponse()).toDomain(),
  );
}

/// DTO nào cũng nullable: `x.orEmpty` giữ nguyên kiểu phần tử (khác với
/// `x ?? const []` bị suy ra `dynamic` khiến gọi extension `toDomain()` lỗi lúc chạy).
extension OrEmptyList<T> on List<T>? {
  List<T> get orEmpty => this ?? <T>[];
}

/// Sách mẫu có bìa đóng gói sẵn thì dùng bìa đó (backend chỉ trả ảnh giả);
/// sách khác giữ ảnh từ API.
List<BookImage> _cover(String? title, String? url) {
  final bundled = bundledCoversFor(title ?? '');
  if (bundled.isNotEmpty) return [for (final p in bundled) BookImage(url: p)];
  return [if (url != null) BookImage(url: url)];
}

List<BookImage> _bundledOr(String? title, List<BookImage> fallback) {
  final bundled = bundledCoversFor(title ?? '');
  return bundled.isEmpty
      ? fallback
      : [for (final p in bundled) BookImage(url: p)];
}
