package com.rebook.consignment;

import com.rebook.system.SystemConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.function.Consumer;

/**
 * Job ký gửi: hết hạn lịch hẹn; người bán không quyết định sau kiểm định; nhắc rồi thanh lý sách không ai nhận lại.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ConsignmentJobs {

    private final ConsignmentRepository repository;
    private final ConsignmentService service;
    private final SystemConfigService config;
    private final WarehouseItemRepository warehouseRepository;

    @Scheduled(fixedDelay = 300_000, initialDelay = 20_000)
    public void expireAppointments() {
        Instant now = Instant.now();
        Instant approvedBefore = now.minus(config.days(SystemConfigService.CONSIGN_APPOINTMENT_DAYS));
        each(repository.findExpiredAppointments(approvedBefore, now), service::expire, "hết hạn ký gửi");
        each(repository.findSellerDecisionOverdueIds(now.minus(config.days(SystemConfigService.CONSIGN_SELLER_DECISION_DAYS))),
                service::expireSellerDecision, "hết hạn người bán quyết định");
        Duration abandonAfter = config.days(SystemConfigService.WAREHOUSE_ABANDON_DAYS);
        Duration notice = Duration.ofDays(ConsignmentService.ABANDON_NOTICE_DAYS);
        each(warehouseRepository.findAbandonWarningIds(now.minus(abandonAfter.minus(notice))), service::warnAbandon, "nhắc sắp thanh lý sách");
        each(warehouseRepository.findAbandonedIds(now.minus(notice)), service::abandon, "thanh lý sách vô chủ");
    }

    private void each(List<Long> ids, Consumer<Long> action, String label) {
        for (Long id : ids) {
            try {
                action.accept(id);
                log.info("Job: {} #{}", label, id);
            } catch (Exception e) {
                log.error("Job: lỗi {} #{}", label, id, e);
            }
        }
    }
}
