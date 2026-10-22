package com.rebook.auction;

import io.swagger.v3.oas.annotations.media.Schema;
import com.rebook.common.StatusFlow;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.EnumSet;
import java.util.Set;

/** Lượt đăng ký tham gia phiên. Hạn mức trả giá = tiền cọc × 10. */
@Entity
@Table(name = "auction_registrations")
@Getter
@Setter
@NoArgsConstructor
public class AuctionRegistration {

    /** PENDING_DEPOSIT → APPROVED (đã khoá cọc) → REFUNDED | APPLIED | FORFEITED. */
    @Schema(name = "RegistrationStatus", enumAsRef = true)
    public enum Status implements StatusFlow<Status> {
        PENDING_DEPOSIT, APPROVED, REFUNDED, APPLIED, FORFEITED;

        @Override
        public Set<Status> nextStates() {
            return switch (this) {
                case PENDING_DEPOSIT -> EnumSet.of(APPROVED, REFUNDED);
                case APPROVED -> EnumSet.of(REFUNDED, APPLIED, FORFEITED);
                case REFUNDED, APPLIED, FORFEITED -> EnumSet.noneOf(Status.class);
            };
        }
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long sessionId;
    private Long userId;
    /** Số bài ẩn danh hiển thị trong phòng thay cho tên thật. */
    private int paddleNumber;
    private BigDecimal depositAmount;
    private BigDecimal bidLimit;

    @Enumerated(EnumType.STRING)
    private Status status = Status.PENDING_DEPOSIT;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;

    public String paddle() {
        return "#" + String.format("%03d", paddleNumber);
    }
}
