package com.rebook.auction;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;

/** Một đơn vị đấu giá. reservePrice KHÔNG bao giờ trả ra API công khai. */
@Entity
@Table(name = "lots")
@Getter
@Setter
@NoArgsConstructor
public class Lot {

    @Schema(name = "LotCloseResult", enumAsRef = true)
    public enum CloseResult { SOLD, RESERVE_NOT_MET, NO_BIDS, CANCELLED }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long sessionId;
    private Long consignmentId;
    private Long bookId;
    private Integer lotNumber;
    private BigDecimal startPrice;
    private BigDecimal reservePrice;
    private BigDecimal estimateLow;
    private BigDecimal estimateHigh;
    private BigDecimal currentPrice;
    private Long currentWinnerId;
    private int bidCount;
    private Instant openedAt;
    private Instant endsAt;
    private Instant closedAt;

    @Enumerated(EnumType.STRING)
    private LotStatus status = LotStatus.READY;

    @Enumerated(EnumType.STRING)
    private CloseResult closeResult;

    private BigDecimal hammerPrice;
    private Long winnerId;

    /** Hoa hồng (%) chụp lúc người bán chấp nhận hợp đồng ký gửi; null = lô cũ, dùng cấu hình hiện tại. */
    private BigDecimal commissionPercent;

    /** Đã nhắc người bán chọn hướng xử lý lô không bán trước hạn. */
    private boolean decisionReminderSent;
    /** Số phiên lô đã được xếp vào (sàn giữ tối đa 2 phiên). */
    private int rounds;

    /**
     * Giá búa cao nhất từng bị người thắng bỏ thanh toán, và phần cọc bị thu mà sàn giữ (BR-6.2).
     * Không xoá khi lô quay lại hàng chờ: dùng để bù chênh cho người bán khi lô bán lại thấp hơn.
     */
    private BigDecimal defaultedHammer;
    private BigDecimal forfeitedPlatformTake = BigDecimal.ZERO;

    @Version
    private Long version;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;

    /** Đưa lô về trạng thái chờ xếp phiên, xoá dữ liệu của lần đấu trước. */
    public void resetToReady() {
        status = status.moveTo(LotStatus.READY);
        sessionId = null;
        lotNumber = null;
        currentPrice = null;
        currentWinnerId = null;
        bidCount = 0;
        openedAt = null;
        endsAt = null;
        closedAt = null;
        closeResult = null;
        hammerPrice = null;
        winnerId = null;
    }
}
