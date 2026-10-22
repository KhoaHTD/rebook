package com.rebook.auction;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface LotRepository extends JpaRepository<Lot, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select l from Lot l where l.id = :id")
    Optional<Lot> lockById(@Param("id") Long id);

    List<Lot> findBySessionIdOrderByLotNumberAsc(Long sessionId);

    Optional<Lot> findFirstBySessionIdAndStatusOrderByLotNumberAsc(Long sessionId, LotStatus status);

    Optional<Lot> findByConsignmentId(Long consignmentId);

    Page<Lot> findByStatusOrderByCreatedAtAsc(LotStatus status, Pageable pageable);

    long countBySessionId(Long sessionId);

    long countByStatus(LotStatus status);

    /**
     * Ghi một lượt trả giá với khoá lạc quan (mục 10.3 đặc tả):
     * chỉ cập nhật khi lô còn mở, chưa hết giờ và chưa ai đổi giá kể từ lúc đọc (version).
     * 0 dòng = có người trả trước → "Giá đã thay đổi".
     */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE lots
               SET current_price = :amount,
                   current_winner_id = :userId,
                   bid_count = bid_count + 1,
                   ends_at = GREATEST(ends_at, :softCloseEnd),
                   version = version + 1,
                   updated_at = now()
             WHERE id = :lotId AND status = 'OPEN' AND version = :version AND ends_at > :now
            """, nativeQuery = true)
    int applyBid(@Param("lotId") Long lotId, @Param("version") Long version, @Param("amount") BigDecimal amount,
                 @Param("userId") Long userId, @Param("softCloseEnd") Instant softCloseEnd, @Param("now") Instant now);

    /** Tổng giá gõ búa các lô người dùng đã thắng trong phiên (tính hạn mức). */
    @Query("""
            select coalesce(sum(l.hammerPrice), 0) from Lot l
            where l.sessionId = :sessionId and l.winnerId = :userId
              and l.status in (com.rebook.auction.LotStatus.SOLD, com.rebook.auction.LotStatus.PAID)
            """)
    BigDecimal sumWonInSession(@Param("sessionId") Long sessionId, @Param("userId") Long userId);

    @Query("""
            select count(l) from Lot l where l.closeResult = com.rebook.auction.Lot.CloseResult.SOLD
            """)
    long countSoldEver();

    @Query("""
            select count(l) from Lot l where l.closeResult is not null
            """)
    long countClosedEver();
}
