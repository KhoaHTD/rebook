package com.rebook.auction;

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

@Entity
@Table(name = "auction_sessions")
@Getter
@Setter
@NoArgsConstructor
public class AuctionSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title;
    private String description;
    private String coverUrl;
    private Instant startAt;
    private Instant registrationDeadline;
    private int minParticipants;
    private BigDecimal depositAmount;
    private int lotDurationSec;
    private int softCloseSec;
    private int lotGapSec;

    @Enumerated(EnumType.STRING)
    private SessionStatus status = SessionStatus.DRAFT;

    private Long currentLotId;
    /** Thời điểm mở lô kế tiếp (nghỉ 5–10 giây giữa các lô). */
    private Instant nextLotAt;
    /** Thời gian còn lại của lô (hoặc khoảng nghỉ) khi bị tạm dừng. */
    private Long pausedRemainingMs;
    private int postponeCount;
    private boolean reminderSent;
    private Instant publishedAt;
    private Instant startedAt;
    private Instant endedAt;
    private Long createdBy;

    @Version
    private Long version;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;
}
