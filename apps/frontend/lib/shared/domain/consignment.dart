import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:book_marketplace/shared/domain/catalog.dart';
import 'package:book_marketplace/shared/domain/enums.dart';
import 'package:book_marketplace/shared/domain/rules.dart';

part 'consignment.freezed.dart';

/// Checklist kiểm định (SRS 6.2).
@freezed
abstract class InspectionChecklist with _$InspectionChecklist {
  const factory InspectionChecklist({
    @Default(true) bool fullPages,
    @Default(true) bool correctEdition,
    @Default(true) bool coverOk,
    @Default(true) bool spineOk,
    @Default(true) bool pagesOk,
    @Default(true) bool noMold,
    @Default(false) bool hasNotes,
    @Default(SignatureStatus.none) SignatureStatus signature,
  }) = _InspectionChecklist;
}

@freezed
abstract class Inspection with _$Inspection {
  const factory Inspection({
    required String id,
    required InspectionResult result,
    required InspectionChecklist checklist,
    required ConditionGrade condition,
    required String conditionReport,
    required List<String> staffImageUrls,
    required SellerDecision sellerDecision,
    required DateTime createdAt,
    int? estimateLow,
    int? estimateHigh,
    int? proposedStart,
    int? proposedReserve,
    int? counterReserve,
  }) = _Inspection;
}

/// Phiếu kiểm định Staff nhập.
@freezed
abstract class InspectionDraft with _$InspectionDraft {
  const factory InspectionDraft({
    required InspectionResult result,
    required InspectionChecklist checklist,
    required ConditionGrade condition,
    required String conditionReport,
    required List<String> staffImageUrls,
    int? estimateLow,
    int? estimateHigh,
    int? proposedStart,
    int? proposedReserve,
  }) = _InspectionDraft;
}

/// Yêu cầu ký gửi đấu giá + lịch hẹn + kết quả (SRS 6.1 – 6.6).
@freezed
abstract class Consignment with _$Consignment {
  const factory Consignment({
    required String id,
    required String sellerName,
    required Book book,
    required int expectedPrice,
    required String story,
    required ConsignmentStatus status,
    required DateTime createdAt,
    String? sellerId,
    String? rejectReason,
    DateTime? approvedAt,
    DateTime? appointmentAt,
    String? appointmentCode,
    DateTime? appointmentExpiresAt,
    DateTime? receivedAt,
    String? warehouseCode,
    Inspection? inspection,
    String? lotId,
    LotStatus? lotStatus,
    int? hammerPrice,
    int? payout,
  }) = _Consignment;
}

@freezed
abstract class AppointmentSlot with _$AppointmentSlot {
  const factory AppointmentSlot({
    required DateTime startAt,
    required bool available,
  }) = _AppointmentSlot;
}

@freezed
abstract class WarehouseItem with _$WarehouseItem {
  const factory WarehouseItem({
    required String id,
    required String consignmentId,
    required String bookTitle,
    required String shelfCode,
    required WarehouseStatus status,
    required DateTime checkedInAt,
    String? sellerName,
    LotStatus? lotStatus,
    DateTime? checkedOutAt,
  }) = _WarehouseItem;
}

/// Cấu hình hệ thống Admin chỉnh (SRS 8.2, 5.3).
@freezed
abstract class SystemConfig with _$SystemConfig {
  const factory SystemConfig({
    required double fixedPriceFeePercent,
    required double buyerPremiumPercent,
    required double sellerCommissionPercent,
    required int storageFeePerDay,
    required int storageFreeDays,
    required int orderPaymentTimeoutMin,
    required int auctionPaymentTimeoutHours,
    required int depositLimitMultiplier,
    required int auctionBanDays,
    required List<BidTier> bidTiers,

    /// order.return_response_days: số ngày shop được trả lời yêu cầu trả hàng (SRS 4.4).
    @Default(2) int returnResponseDays,
  }) = _SystemConfig;
}

@freezed
abstract class Dashboard with _$Dashboard {
  const factory Dashboard({
    required int revenueTotal,
    required int platformFees,
    required int orderCount,
    required double lotSoldRate,
    required int activeUsers,
    required int pendingListings,
    required int pendingConsignments,
  }) = _Dashboard;
}
