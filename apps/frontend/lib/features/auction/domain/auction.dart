import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/shared/domain/book.dart';

part 'auction.freezed.dart';

/// Bước giá theo bậc (giống cấu hình mặc định của backend):
/// < 200k: 10k · < 1tr: 50k · < 5tr: 100k · từ 5tr: 500k.
int bidIncrementFor(int price) => price < 200000
    ? 10000
    : price < 1000000
    ? 50000
    : price < 5000000
    ? 100000
    : 500000;

/// Trạng thái live của một lô đang đấu (phòng đấu giá).
@freezed
abstract class Auction with _$Auction {
  const Auction._();

  const factory Auction({
    required String id,
    required Book book,
    required int currentPrice,
    required int minIncrement,
    required DateTime endsAt,
    required int bidCount,
    String? highestBidder,

    /// Người đang giữ giá cao nhất là chính người dùng.
    @Default(false) bool youAreLeading,

    /// Lượt trả giá gần nhất, mới nhất trước.
    @Default(<BidEntry>[]) List<BidEntry> recentBids,

    /// Đã vượt giá sàn chưa (null = backend chưa báo). Không bao giờ có con số giá sàn.
    bool? reserveMet,
    int? lotNumber,
    int? lotCount,
    String? sessionTitle,
    String? edition,
    int? estimateLow,
    int? estimateHigh,
    int? viewerCount,

    /// Hạn mức trả giá của người dùng trong phiên (cọc × 10).
    int? bidLimit,

    /// Giá tối đa tự trả (proxy) người dùng đã bật; null = tắt.
    int? proxyMax,

    /// true khi đồng hồ vừa được cộng thêm do có giá mới trong những giây cuối.
    @Default(false) bool softCloseExtended,

    /// Lúc lô bắt đầu nhận giá. null = đang mở.
    DateTime? opensAt,

    /// Thời lượng gốc của lô — để vẽ vòng đếm ngược.
    @Default(60) int lotDurationSeconds,

    /// Giá tối thiểu lượt kế tiếp do server tính (chưa ai trả = giá khởi điểm).
    int? serverNextMinBid,
  }) = _Auction;

  /// Giá thấp nhất được phép trả tiếp theo.
  int get nextMinBid => serverNextMinBid ?? currentPrice + minIncrement;

  bool isEndedAt(DateTime now) => !now.isBefore(endsAt);

  /// Đang nhận giá: đã mở và chưa hết giờ.
  bool isLiveAt(DateTime now) =>
      !isEndedAt(now) && (opensAt == null || !now.isBefore(opensAt!));

  bool exceedsLimit(int amount) => bidLimit != null && amount > bidLimit!;
}

@freezed
abstract class BidEntry with _$BidEntry {
  const factory BidEntry({
    /// Số bài ẩn danh, vd "#027" — không bao giờ là tên thật.
    required String paddle,
    required int amount,
    required DateTime at,
    @Default(false) bool isYou,

    /// Do hệ thống trả hộ (giá tối đa / đặt trước khi vào phiên).
    @Default(false) bool auto,
  }) = _BidEntry;
}

/// Catalogue một lô trước phiên: ảnh, báo cáo kiểm định, giá ước tính, điều kiện tham gia.
@freezed
abstract class LotDetail with _$LotDetail {
  const LotDetail._();

  const factory LotDetail({
    required String id,
    required Book book,
    required int startPrice,
    required int minIncrement,
    required DateTime opensAt,
    int? lotNumber,
    int? lotCount,
    String? sessionTitle,
    String? edition,
    int? estimateLow,
    int? estimateHigh,
    int? deposit,
    int? bidLimit,
    int? lotDurationSeconds,
    int? softCloseSeconds,

    /// % phí người mua cộng vào giá gõ búa.
    @Default(10) int buyerPremiumPercent,
    String? inspector,
    DateTime? inspectedAt,

    /// Đoạn mô tả tình trạng do nhân viên kiểm định viết.
    String? conditionReport,
    @Default(<InspectionItem>[]) List<InspectionItem> inspection,
    @Default(false) bool following,
    @Default(false) bool isLive,

    /// Đã đăng ký + đặt cọc cho phiên chứa lô này.
    @Default(false) bool registered,
  }) = _LotDetail;

  /// Ước tính tổng tiền nếu thắng ở [hammer] (chưa gồm phí giao).
  int totalIfWon(int hammer) =>
      hammer + (hammer * buyerPremiumPercent / 100).round();
}

/// Các mục trong checklist kiểm định.
enum InspectionCheck { fullPages, edition, mold, notes, signature }

@freezed
abstract class InspectionItem with _$InspectionItem {
  const factory InspectionItem({
    required InspectionCheck check,

    /// true = đạt, false = có lưu ý.
    required bool ok,

    /// Ghi chú thêm (vd chữ ký "chưa xác thực").
    String? note,
  }) = _InspectionItem;
}
