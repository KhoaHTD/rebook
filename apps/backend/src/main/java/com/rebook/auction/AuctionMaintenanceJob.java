package com.rebook.auction;

import com.rebook.config.AppProperties;
import com.rebook.consignment.ConsignmentService;
import com.rebook.system.SystemConfigService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;

/**
 * Việc định kỳ của đấu giá ngoài bộ máy chạy phiên: lô không bán / bị huỷ mà người bán không chọn hướng xử lý
 * trong {@code auction.unsold_decision_days} ngày thì tự chuyển sang trả sách (bắt đầu hạn lưu kho miễn phí).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuctionMaintenanceJob {

    private final LotRepository lotRepository;
    private final ConsignmentService consignmentService;
    private final SystemConfigService config;
    private final AppProperties props;

    @Scheduled(fixedDelay = 3_600_000, initialDelay = 60_000)
    public void run() {
        if (props.auction().engineEnabled()) {
            runOnce();
        }
    }

    /** Trả về số lô đã tự chuyển sang trả sách. */
    public int runOnce() {
        Instant before = Instant.now().minus(config.days(SystemConfigService.UNSOLD_DECISION_DAYS));
        int done = 0;
        for (Lot lot : lotRepository.findByStatusInAndClosedAtBefore(List.of(LotStatus.UNSOLD, LotStatus.CANCELLED), before)) {
            try {
                consignmentService.autoReturnUnsold(lot.getId());
                done++;
            } catch (Exception e) {
                log.error("Job: lỗi tự trả sách lô #{}", lot.getId(), e);
            }
        }
        // Nhắc những lô sắp tới hạn (chạy sau bước tự trả sách để không nhắc lô vừa bị chuyển)
        Instant remindBefore = before.plus(config.hours(SystemConfigService.REMINDER_HOURS));
        for (Long id : lotRepository.findDecisionReminderIds(List.of(LotStatus.UNSOLD, LotStatus.CANCELLED), remindBefore)) {
            try {
                consignmentService.sendDecisionReminder(id);
            } catch (Exception e) {
                log.error("Job: lỗi nhắc quyết định lô #{}", id, e);
            }
        }
        return done;
    }
}
