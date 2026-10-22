package com.rebook.consignment;

import com.rebook.system.SystemConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;

/** Hết hạn lịch hẹn ký gửi: quá 7 ngày kể từ khi được duyệt mà chưa mang sách tới. */
@Slf4j
@Component
@RequiredArgsConstructor
public class ConsignmentJobs {

    private final ConsignmentRepository repository;
    private final ConsignmentService service;
    private final SystemConfigService config;

    @Scheduled(fixedDelay = 300_000, initialDelay = 20_000)
    public void expireAppointments() {
        Instant now = Instant.now();
        Instant approvedBefore = now.minus(config.days(SystemConfigService.CONSIGN_APPOINTMENT_DAYS));
        for (Long id : repository.findExpiredAppointments(approvedBefore, now)) {
            try {
                service.expire(id);
                log.info("Job: hết hạn ký gửi #{}", id);
            } catch (Exception e) {
                log.error("Job: lỗi hết hạn ký gửi #{}", id, e);
            }
        }
    }
}
