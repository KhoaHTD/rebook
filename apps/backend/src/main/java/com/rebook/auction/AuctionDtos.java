package com.rebook.auction;

import com.rebook.catalog.CatalogDtos.BookResponse;
import com.rebook.catalog.ConditionGrade;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

public final class AuctionDtos {

    private AuctionDtos() {
    }

    // ---- Admin ----

    public record SessionRequest(
            @NotBlank @Size(max = 200) String title,
            @Size(max = 5000) String description,
            @Size(max = 500) String coverUrl,
            @NotNull Instant startAt,
            @NotNull Instant registrationDeadline,
            @NotNull @Min(1) Integer minParticipants,
            @NotNull @DecimalMin("0") BigDecimal depositAmount,
            @Min(10) @Max(600) Integer lotDurationSec,
            @Min(5) @Max(120) Integer softCloseSec,
            @Min(0) @Max(60) Integer lotGapSec) {
    }

    /** Danh sách lô theo đúng thứ tự chạy (lô hấp dẫn nên đặt ở giữa để giữ người xem). */
    public record AssignLotsRequest(@NotEmpty List<Long> lotIds) {
    }

    // ---- Người mua ----

    public record RegisterRequest(boolean agreeRules) {
    }

    /** Cọc thêm để nâng hạn mức trả giá. */
    public record AddDepositRequest(@NotNull @DecimalMin("10000") BigDecimal amount) {
    }

    public record BidRequest(@NotNull BigDecimal amount) {
    }

    public record ProxyBidRequest(@NotNull BigDecimal maxAmount) {
    }

    /** Hoá đơn lô thắng: giao về địa chỉ (addressId) hoặc nhận tại kho. */
    public record DeliveryOptionRequest(Long addressId, boolean pickupAtWarehouse) {
    }

    // ---- Response ----

    public record SessionSummary(Long id, String title, String description, String coverUrl, Instant startAt,
                                 Instant registrationDeadline, int minParticipants, BigDecimal depositAmount,
                                 SessionStatus status, long lotCount, long registeredCount, Instant endedAt) {
    }

    public record LotPublic(Long id, Long sessionId, Integer lotNumber, LotStatus status, Lot.CloseResult closeResult,
                            String title, String author, String coverUrl, ConditionGrade conditionGrade,
                            BigDecimal estimateLow, BigDecimal estimateHigh, BigDecimal startPrice,
                            BigDecimal currentPrice, int bidCount, Instant endsAt, BigDecimal hammerPrice,
                            String winnerPaddle, boolean watching) {
    }

    public record LotDetail(LotPublic lot, BookResponse book, String conditionReport, Map<String, Object> checklist,
                            String provenance, SessionSummary session) {
    }

    public record RegistrationResponse(Long id, Long sessionId, String paddle, BigDecimal depositAmount,
                                       BigDecimal bidLimit, BigDecimal committed, BigDecimal remainingLimit,
                                       AuctionRegistration.Status status, Instant createdAt) {
    }

    public record SessionDetail(SessionSummary session, int lotDurationSec, int softCloseSec, List<LotPublic> lots,
                                RegistrationResponse myRegistration) {
    }

    public record BidView(String paddle, BigDecimal amount, boolean auto, Instant at) {
    }

    /** Trạng thái lô đang đấu, dùng cho phòng đấu giá. App tự đếm ngược theo endsAt + serverTime. */
    public record LotLive(Long id, Integer lotNumber, String title, String coverUrl, LotStatus status,
                          BigDecimal startPrice, BigDecimal currentPrice, BigDecimal nextMinBid,
                          BigDecimal increment, int bidCount, Instant endsAt, String leadingPaddle,
                          List<BidView> recentBids, Lot.CloseResult closeResult, BigDecimal hammerPrice) {
    }

    /** Ảnh chụp trạng thái phòng — gọi khi vào phòng / kết nối lại rồi mới nghe tiếp WebSocket. */
    public record SessionState(Instant serverTime, Long sessionId, SessionStatus status, LotLive currentLot,
                               Instant nextLotAt, long remainingLots, Long pausedRemainingMs,
                               RegistrationResponse me, BigDecimal myProxyMax) {
    }

    /**
     * Sự kiện phát tới /ws/sessions/{id}: SESSION_STARTED, LOT_OPENED, BID_PLACED, LOT_CLOSED,
     * SESSION_PAUSED, SESSION_RESUMED, SESSION_ENDED, SESSION_CANCELLED.
     */
    public record AuctionEvent(String type, Long sessionId, Instant serverTime, SessionStatus sessionStatus,
                               LotLive lot, Instant nextLotAt, String message) {
    }

    public record LotResult(Integer lotNumber, Long lotId, String title, Lot.CloseResult result,
                            BigDecimal hammerPrice, String winnerPaddle) {
    }

    public record BidResponse(LotLive lot, boolean leading, RegistrationResponse me) {
    }
}
