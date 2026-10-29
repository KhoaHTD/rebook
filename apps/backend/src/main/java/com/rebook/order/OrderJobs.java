package com.rebook.order;

import com.rebook.system.SystemConfigService;
import com.rebook.wallet.PaymentService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.function.Consumer;

/**
 * Các hạn tự động của đơn hàng (mỗi phút):
 * huỷ đơn chưa thanh toán sau 15 phút, huỷ đơn shop không xác nhận trong 24h,
 * tự hoàn tất đơn sau 3 ngày kể từ khi giao, chuyển Admin yêu cầu trả hàng người bán không trả lời sau 2 ngày.
 * Mỗi đơn xử lý trong transaction riêng.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OrderJobs {

    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final ReturnRequestRepository returnRepository;
    private final PaymentService paymentService;
    private final SystemConfigService config;

    @Scheduled(fixedDelay = 60_000, initialDelay = 10_000)
    public void run() {
        Instant now = Instant.now();
        paymentService.expireStalePayments();
        each(orderRepository.findUnpaidNormalOrderIds(now), orderService::autoCancelUnpaid, "huỷ đơn chưa thanh toán");
        each(orderRepository.findUnconfirmedOrderIds(now), orderService::autoCancelUnconfirmed, "huỷ đơn shop không xác nhận");
        each(orderRepository.findDeliveredBefore(now.minus(config.days(SystemConfigService.AUTO_COMPLETE_DAYS))),
                orderService::autoComplete, "tự hoàn tất đơn");
        each(returnRepository.findUnansweredOrderIds(now.minus(config.days(SystemConfigService.RETURN_RESPONSE_DAYS))),
                orderService::autoEscalateReturn, "chuyển Admin yêu cầu trả hàng quá hạn");
    }

    private void each(List<Long> ids, Consumer<Long> action, String label) {
        for (Long id : ids) {
            try {
                action.accept(id);
                log.info("Job: {} #{}", label, id);
            } catch (Exception e) {
                log.error("Job: lỗi khi {} #{}", label, id, e);
            }
        }
    }
}
