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
        each(orderRepository.findShippedBefore(now.minus(config.days(SystemConfigService.AUTO_DELIVER_DAYS))),
                orderService::autoDeliver, "tự coi là đã giao");
        each(returnRepository.findNotShippedOrderIds(now.minus(config.days(SystemConfigService.RETURN_SHIP_DAYS))),
                orderService::autoExpireReturn, "đóng yêu cầu trả hàng không gửi hàng về");
        each(returnRepository.findShippedUnconfirmedOrderIds(now.minus(config.days(SystemConfigService.RETURN_CONFIRM_DAYS))),
                orderService::autoEscalateGoods, "chuyển Admin hàng trả shop không xác nhận");
        each(orderRepository.findOverdueToShipIds(now), orderService::autoCancelUnshipped, "huỷ đơn shop không giao đúng hạn");
        each(orderRepository.findUnansweredCancelRequestIds(now.minus(config.hours(SystemConfigService.CANCEL_RESPONSE_HOURS))),
                orderService::autoApproveCancelRequest, "tự đồng ý huỷ đơn shop không trả lời");
        Instant remindBefore = now.plus(config.hours(SystemConfigService.REMINDER_HOURS));
        each(orderRepository.findShipReminderIds(now, remindBefore), orderService::sendShipReminder, "nhắc shop sắp quá hạn giao");
        each(orderRepository.findCancelReminderIds(now.minus(config.hours(SystemConfigService.CANCEL_RESPONSE_HOURS).dividedBy(2))),
                orderService::sendCancelReminder, "nhắc shop trả lời yêu cầu huỷ");
        each(orderRepository.findPaymentReminderIds(now, remindBefore), orderService::sendPaymentReminder, "nhắc người thắng thanh toán");
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
