package com.rebook.notification;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface EmailOutboxRepository extends JpaRepository<EmailOutbox, Long> {

    @Query("select e.id from EmailOutbox e where e.status = com.rebook.notification.EmailOutbox.Status.PENDING "
            + "and e.nextAttemptAt <= :now order by e.id")
    List<Long> findDueIds(@Param("now") Instant now, Pageable page);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from EmailOutbox e where e.id = :id")
    Optional<EmailOutbox> lockById(@Param("id") Long id);

    @Modifying
    @Query("delete from EmailOutbox e where e.status = com.rebook.notification.EmailOutbox.Status.SENT and e.sentAt < :before")
    int deleteSentBefore(@Param("before") Instant before);

    /**
     * Người mua chưa được báo về hoá đơn lô thắng: thư AUCTION_WON của đơn này chưa gửi được (đang chờ hoặc thất bại)
     * và thông báo trong app cũng chưa đọc. Không có thư (mail tắt, email chưa xác thực) thì coi như đã báo bằng app.
     */
    @Query(value = """
            SELECT EXISTS (
                SELECT 1 FROM email_outbox e JOIN notifications n ON n.id = e.notification_id
                WHERE n.user_id = :userId AND n.type = 'AUCTION_WON' AND n.data ->> 'orderId' = CAST(:orderId AS TEXT)
                  AND e.status <> 'SENT' AND NOT n.is_read)""", nativeQuery = true)
    boolean winNoticeUndelivered(@Param("userId") Long userId, @Param("orderId") Long orderId);
}
