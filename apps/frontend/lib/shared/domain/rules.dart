import 'package:book_marketplace/shared/domain/enums.dart';

/// Quy tắc nghiệp vụ thuần, dùng chung cho UI, dữ liệu giả và test.
/// Backend là nơi quyết định cuối cùng; app dùng để hiển thị và kiểm tra sớm.

/// Một bậc bước giá: từ [fromPrice] trở lên, bước tối thiểu là [increment].
class BidTier {
  const BidTier(this.fromPrice, this.increment);
  final int fromPrice;
  final int increment;
}

/// Bảng bước giá gợi ý (SRS 5.3). Admin cấu hình được.
const defaultBidTiers = [
  BidTier(0, 10000),
  BidTier(200000, 50000),
  BidTier(1000000, 100000),
  BidTier(5000000, 500000),
];

/// Bước giá tối thiểu tại mức giá hiện tại.
int bidIncrementFor(int currentPrice, [List<BidTier> tiers = defaultBidTiers]) {
  var step = tiers.first.increment;
  for (final t in tiers) {
    if (currentPrice >= t.fromPrice) step = t.increment;
  }
  return step;
}

/// Số tiền của nút "Trả Xđ": giá khởi điểm nếu chưa ai trả, ngược lại giá hiện tại + bước.
int nextBidAmount({
  required int currentPrice,
  required int bidCount,
  List<BidTier> tiers = defaultBidTiers,
}) => bidCount == 0
    ? currentPrice
    : currentPrice + bidIncrementFor(currentPrice, tiers);

/// Phí và hoa hồng (SRS 8.2). Phần trăm dạng 10 = 10%.
class FeeConfig {
  const FeeConfig({
    this.fixedPriceFeePercent = 5,
    this.buyerPremiumPercent = 10,
    this.sellerCommissionPercent = 15,
    this.depositLimitMultiplier = 10,
    this.storageFeePerDay = 5000,
    this.storageFreeDays = 14,
  });

  final double fixedPriceFeePercent;
  final double buyerPremiumPercent;
  final double sellerCommissionPercent;
  final int depositLimitMultiplier;
  final int storageFeePerDay;
  final int storageFreeDays;

  int buyerPremium(int hammerPrice) =>
      (hammerPrice * buyerPremiumPercent / 100).round();
  int sellerCommission(int hammerPrice) =>
      (hammerPrice * sellerCommissionPercent / 100).round();
  int fixedPriceFee(int amount) =>
      (amount * fixedPriceFeePercent / 100).round();
  int bidLimit(int deposit) => deposit * depositLimitMultiplier;
}

/// Giai đoạn đếm ngược của một lô (SRS 6.5):
/// còn ≤ 10 giây: "Lần thứ nhất", ≤ 5 giây: "Lần thứ hai", hết giờ: "Bán!".
enum HammerPhase { open, firstCall, secondCall, closed }

HammerPhase hammerPhase(Duration remaining) {
  if (remaining <= Duration.zero) return HammerPhase.closed;
  if (remaining <= const Duration(seconds: 5)) return HammerPhase.secondCall;
  if (remaining <= const Duration(seconds: 10)) return HammerPhase.firstCall;
  return HammerPhase.open;
}

/// Chuyển trạng thái đơn hợp lệ (SRS 7.3). Backend trả 409 nếu chuyển sai.
const orderTransitions = <OrderStatus, Set<OrderStatus>>{
  OrderStatus.pendingPayment: {
    OrderStatus.pendingConfirm,
    OrderStatus.cancelled,
  },
  OrderStatus.pendingConfirm: {OrderStatus.preparing, OrderStatus.cancelled},
  OrderStatus.preparing: {OrderStatus.shipping, OrderStatus.cancelled},
  OrderStatus.shipping: {OrderStatus.delivered, OrderStatus.failedDelivery},
  OrderStatus.delivered: {OrderStatus.completed, OrderStatus.returnRequested},
  OrderStatus.returnRequested: {OrderStatus.returned, OrderStatus.completed},
};

bool canTransition(OrderStatus from, OrderStatus to) =>
    orderTransitions[from]?.contains(to) ?? false;

/// Trạng thái phiên chuyển hợp lệ (SRS 7.2).
const sessionTransitions = <SessionStatus, Set<SessionStatus>>{
  SessionStatus.draft: {SessionStatus.published},
  SessionStatus.published: {
    SessionStatus.confirmed,
    SessionStatus.postponed,
    SessionStatus.cancelled,
  },
  SessionStatus.postponed: {SessionStatus.published, SessionStatus.cancelled},
  SessionStatus.confirmed: {SessionStatus.live},
  SessionStatus.live: {SessionStatus.paused, SessionStatus.ended},
  SessionStatus.paused: {SessionStatus.live},
};

/// Ký gửi bị từ chối sơ duyệt nếu giá mong muốn dưới ngưỡng này (SRS 6.1).
const consignmentMinExpectedPrice = 300000;
