package com.rebook.auction;

import com.rebook.config.AppProperties;
import com.rebook.order.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.function.Consumer;

/**
 * Bộ máy chạy phiên tự động (mục 10.3): server giữ đồng hồ, quét mỗi giây.
 * Không cần người bấm: đóng đăng ký và kiểm đủ người, mở phiên đúng giờ, chạy từng lô,
 * chốt lô, tạo hoá đơn, hoàn cọc; mỗi phút xử lý hoá đơn quá hạn 48h.
 * Chỉ chạy được trên MỘT instance backend (đồ án không cần chạy nhiều instance).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class AuctionEngine {

    private static final Duration REMINDER_BEFORE = Duration.ofMinutes(15);

    private final AuctionSessionRepository sessionRepository;
    private final OrderRepository orderRepository;
    private final AuctionRunner runner;
    private final AuctionSettlement settlement;
    private final AppProperties props;

    @Scheduled(fixedRate = 1000, initialDelay = 5000)
    public void tick() {
        if (!props.auction().engineEnabled()) {
            return;
        }
        Instant now = Instant.now();
        each(sessionRepository.findRegistrationClosed(now), runner::checkQuorum, "kiểm đủ người");
        each(sessionRepository.findNeedReminder(now.plus(REMINDER_BEFORE)), runner::sendReminder, "nhắc lịch");
        each(sessionRepository.findDueToStart(now), runner::start, "mở phiên");
        each(sessionRepository.findLiveIds(), runner::tick, "chạy phiên");
    }

    @Scheduled(fixedDelay = 60_000, initialDelay = 15_000)
    public void overdueInvoices() {
        if (!props.auction().engineEnabled()) {
            return;
        }
        each(orderRepository.findOverdueAuctionOrderIds(Instant.now()), settlement::handleOverdue, "hoá đơn quá hạn");
    }

    private void each(List<Long> ids, Consumer<Long> action, String label) {
        for (Long id : ids) {
            try {
                action.accept(id);
            } catch (Exception e) {
                log.error("Engine: lỗi khi {} #{}", label, id, e);
            }
        }
    }
}
