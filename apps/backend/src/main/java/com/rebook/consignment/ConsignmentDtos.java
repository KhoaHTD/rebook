package com.rebook.consignment;

import io.swagger.v3.oas.annotations.media.Schema;
import com.rebook.auction.Lot;
import com.rebook.auction.LotStatus;
import com.rebook.catalog.CatalogDtos.BookRequest;
import com.rebook.catalog.CatalogDtos.BookResponse;
import com.rebook.catalog.ConditionGrade;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

public final class ConsignmentDtos {

    private ConsignmentDtos() {
    }

    // ---- Người bán ----

    public record ConsignmentCreateRequest(@NotNull @Valid BookRequest book,
                                           @NotNull @DecimalMin("1000") BigDecimal expectedPrice,
                                           @Size(max = 2000) String provenance) {
    }

    public record AppointmentRequest(@NotNull @Future Instant appointmentAt) {
    }

    @Schema(name = "SellerDecisionAction", enumAsRef = true)
    public enum Decision { ACCEPT, WITHDRAW }

    /**
     * ACCEPT: đồng ý hợp đồng ký gửi (bắt buộc agreeTerms = true). Có thể kèm counterReserve
     * (đề nghị giá sàn khác, không vượt mức thấp của giá ước tính).
     */
    public record SellerDecisionRequest(@NotNull Decision decision, BigDecimal counterReserve, boolean agreeTerms) {
    }

    @Schema(name = "UnsoldAction", enumAsRef = true)
    public enum UnsoldAction { RELIST, CONVERT_TO_LISTING, RETURN }

    /** Lô không bán được: vào phiên sau (có thể hạ giá sàn), chuyển sang bán giá cố định, hoặc nhận lại. */
    public record UnsoldDecisionRequest(@NotNull UnsoldAction action, BigDecimal newReserve, BigDecimal listingPrice) {
    }

    // ---- Staff ----

    @io.swagger.v3.oas.annotations.media.Schema(name = "ConsignmentReviewRequest")
    public record ReviewRequest(boolean approve, @Size(max = 500) String note) {
    }

    public record CheckInRequest(@Size(max = 30) String shelfCode, List<@NotBlank String> photoUrls) {
    }

    public record InspectionRequest(
            @NotNull Inspection.Result result,
            Map<String, Object> checklist,
            ConditionGrade conditionGrade,
            @NotBlank @Size(max = 5000) String conditionReport,
            List<@NotBlank String> photoUrls,
            BigDecimal estimateLow,
            BigDecimal estimateHigh,
            BigDecimal proposedStart,
            BigDecimal proposedReserve) {
    }

    public record ShelfRequest(@NotBlank @Size(max = 30) String shelfCode) {
    }

    // ---- Response ----

    public record InspectionResponse(Long id, Inspection.Result result, Map<String, Object> checklist,
                                     ConditionGrade conditionGrade, String conditionReport, BigDecimal estimateLow,
                                     BigDecimal estimateHigh, BigDecimal proposedStart, BigDecimal proposedReserve,
                                     Inspection.SellerDecision sellerDecision, BigDecimal sellerCounterReserve,
                                     Instant decidedAt, Instant createdAt) {

        public static InspectionResponse of(Inspection i) {
            return new InspectionResponse(i.getId(), i.getResult(), i.getChecklist(), i.getConditionGrade(),
                    i.getConditionReport(), i.getEstimateLow(), i.getEstimateHigh(), i.getProposedStart(),
                    i.getProposedReserve(), i.getSellerDecision(), i.getSellerCounterReserve(), i.getDecidedAt(),
                    i.getCreatedAt());
        }
    }

    /** Thông tin lô cho người ký gửi (được xem giá sàn của chính mình). */
    public record LotBrief(Long id, LotStatus status, Long sessionId, Integer lotNumber, BigDecimal startPrice,
                           BigDecimal reservePrice, BigDecimal hammerPrice, Lot.CloseResult closeResult, int rounds) {

        public static LotBrief of(Lot l) {
            return new LotBrief(l.getId(), l.getStatus(), l.getSessionId(), l.getLotNumber(), l.getStartPrice(),
                    l.getReservePrice(), l.getHammerPrice(), l.getCloseResult(), l.getRounds());
        }
    }

    public record WarehouseResponse(Long id, String code, Long consignmentId, String bookTitle, String shelfCode,
                                    WarehouseItem.Status status, Instant checkedInAt, Instant checkedOutAt,
                                    String checkoutReason, Instant returnNotifiedAt, BigDecimal storageFee) {

        public static WarehouseResponse of(WarehouseItem w, String bookTitle) {
            return new WarehouseResponse(w.getId(), w.getCode(), w.getConsignmentId(), bookTitle, w.getShelfCode(),
                    w.getStatus(), w.getCheckedInAt(), w.getCheckedOutAt(), w.getCheckoutReason(),
                    w.getReturnNotifiedAt(), w.getStorageFee());
        }
    }

    public record ConsignmentResponse(Long id, String code, ConsignmentStatus status, Long sellerId, String sellerName,
                                      BookResponse book, BigDecimal expectedPrice, String provenance,
                                      String reviewNote, Instant appointmentAt, String appointmentCode,
                                      Instant approvedAt, Instant receivedAt, InspectionResponse inspection,
                                      LotBrief lot, WarehouseResponse warehouse, Instant createdAt,
                                      Instant updatedAt) {
    }
}
