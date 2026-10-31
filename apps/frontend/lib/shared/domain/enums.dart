/// Các enum nghiệp vụ dùng chung, bám theo SRS mục 4, 6, 7 và 8.
library;

/// Thang tình trạng sách chuẩn (SRS 4.1), bắt buộc khi đăng bán.
enum ConditionGrade { brandNew, likeNew, veryGood, good, acceptable, unknown }

enum UserRole { user, staff, admin }

enum ListingStatus { pendingReview, active, hidden, outOfStock, rejected }

enum ListingSort { newest, priceAsc, priceDesc, relevance }

/// NORMAL: shop giao. AUCTION: kho của sàn giao, sàn nhận tiền (SRS 7.3).
enum OrderType { normal, auction }

/// Trạng thái đơn hàng (SRS 7.3).
enum OrderStatus {
  pendingPayment,
  pendingConfirm,
  preparing,
  shipping,
  delivered,
  returnRequested,
  completed,
  cancelled,
  returned,
  failedDelivery;

  bool get isFinal =>
      this == completed ||
      this == cancelled ||
      this == returned ||
      this == failedDelivery;
}

enum PaymentMethod { cod, wallet, vnpay }

enum PaymentStatus { pending, success, failed, expired }

enum ReturnStatus {
  pending,
  accepted,
  rejected,
  escalated,
  resolvedRefund,
  resolvedNoRefund,

  /// Người mua bấm "Đã nhận hàng" khi đang yêu cầu trả hàng: coi như rút yêu cầu (SRS 4.4).
  withdrawn,
}

/// Loại giao dịch ví (SRS 8.1). Mọi thay đổi số dư là một dòng sổ cái.
enum WalletTxnType {
  topUp,
  payment,
  refund,
  depositHold,
  depositRelease,
  depositForfeit,
  salePending,
  saleRelease,
  fee,
  withdraw,
}

enum WithdrawalStatus { pending, completed, rejected }

/// Thao tác của Admin được ghi vào nhật ký hoạt động (SRS 8.1).
enum AdminAction {
  listingApproved,
  listingRejected,
  userLocked,
  userUnlocked,
  roleChanged,
  auctionBanLifted,
  shopMarkedTrusted,
  withdrawalCompleted,
  configChanged,
}

/// Lời mời mua lần hai (SRS 6.6).
enum SecondChanceStatus { pending, accepted, declined, expired }

/// Vòng đời ký gửi trước khi thành lô (SRS 6.1 – 6.2).
enum ConsignmentStatus {
  submitted,
  preApproved,
  preRejected,
  appointmentBooked,
  expired,
  received,
  inspected,
  inspectionFailed,
  accepted,
  withdrawn,
  returned,
}

/// Trạng thái lô (SRS 7.1).
enum LotStatus {
  ready,
  scheduled,
  live,
  sold,
  unsold,
  completed,
  returned,
  cancelled,
}

enum LotOutcome { sold, belowReserve, noBids, cancelled }

/// Trạng thái phiên đấu giá (SRS 7.2).
enum SessionStatus {
  draft,
  published,
  postponed,
  confirmed,
  live,
  paused,
  ended,
  cancelled,
}

/// Lượt đăng ký tham gia (SRS 7.4).
enum RegistrationStatus {
  pendingDeposit,
  approved,
  refunded,
  applied,
  forfeited,
}

enum WarehouseStatus { inStock, reserved, shipped, returned }

enum InspectionResult { pass, fail }

enum SignatureStatus { none, unverified, verified }

enum SellerDecision { pending, accept, counter, withdraw }

/// Lô không bán được: phiên sau / bán giá cố định / nhận lại (SRS 6.6).
enum UnsoldChoice { nextSession, fixedPrice, returnToSeller }

enum NotificationType {
  order,
  auctionReminder,
  outbid,
  auctionWon,
  auctionResult,
  consignment,
  wallet,
  system,
}
