package com.rebook.notification;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

/**
 * Gửi thư trong {@code email_outbox} mỗi 30 giây, mỗi thư một giao dịch.
 * Lỗi thì thử lại sau 1 phút, 5 phút, 30 phút, 2 giờ; lần thứ 5 vẫn lỗi thì FAILED
 * (hoá đơn đấu giá có thư FAILED mà thông báo chưa đọc thì không bị phạt, xem AuctionSettlement.handleOverdue).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class EmailOutboxJob {

    static final List<Duration> RETRY_AFTER = List.of(Duration.ofMinutes(1), Duration.ofMinutes(5),
            Duration.ofMinutes(30), Duration.ofHours(2));
    private static final Duration KEEP_SENT = Duration.ofDays(30);

    private final EmailOutboxRepository repository;
    private final MailService mail;
    private final AuditLog audit;
    private final TransactionTemplate tx;

    @Scheduled(fixedDelay = 30_000, initialDelay = 15_000)
    public void run() {
        for (Long id : repository.findDueIds(Instant.now(), PageRequest.of(0, 50))) {
            try {
                tx.executeWithoutResult(s -> deliver(id));
            } catch (Exception e) {
                log.error("Job: lỗi khi gửi thư #{}", id, e);
            }
        }
        tx.executeWithoutResult(s -> repository.deleteSentBefore(Instant.now().minus(KEEP_SENT)));
    }

    void deliver(Long id) {
        EmailOutbox e = repository.lockById(id).orElse(null);
        if (e == null || e.getStatus() != EmailOutbox.Status.PENDING) {
            return;
        }
        try {
            mail.send(e.getToEmail(), e.getSubject(), e.getBody());
            e.setStatus(EmailOutbox.Status.SENT);
            e.setSentAt(Instant.now());
            e.setLastError(null);
            audit.record(EventCode.MAIL_SENT, "USER", e.getUserId(), null, "Đã gửi thư", "outboxId", id, "subject", e.getSubject());
        } catch (RuntimeException ex) {
            int attempts = e.getAttempts() + 1;
            e.setAttempts(attempts);
            String err = String.valueOf(ex.getMessage());
            e.setLastError(err.length() > 500 ? err.substring(0, 500) : err);
            if (attempts > RETRY_AFTER.size()) {
                e.setStatus(EmailOutbox.Status.FAILED);
                audit.record(EventCode.MAIL_FAILED, "USER", e.getUserId(), null, "Gửi thư thất bại sau nhiều lần thử",
                        "outboxId", id, "attempts", attempts);
            } else {
                e.setNextAttemptAt(Instant.now().plus(RETRY_AFTER.get(attempts - 1)));
            }
            log.warn("Gửi thư #{} lỗi lần {}: {}", id, attempts, err);
        }
    }
}
