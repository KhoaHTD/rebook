package com.rebook.order;

import com.rebook.audit.AuditLog;
import com.rebook.audit.EventCode;
import com.rebook.notification.NotificationService;
import com.rebook.system.SystemConfigService;
import com.rebook.user.Shop;
import com.rebook.user.ShopRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

/**
 * Điểm uy tín shop: tỷ lệ đơn hỏng do lỗi của shop (huỷ, không xác nhận, không giao) trong khoảng theo dõi.
 * Shop uy tín mà vượt ngưỡng thì bị gỡ uy tín, tức là tin đăng lại phải chờ Admin duyệt. Admin gắn lại được.
 */
@Service
@RequiredArgsConstructor
public class ShopReputation {

    private final ShopRepository shopRepository;
    private final OrderRepository orderRepository;
    private final SystemConfigService config;
    private final AuditLog audit;
    private final NotificationService notifications;

    /** Gọi sau khi một đơn của shop vừa bị đánh dấu lỗi do shop. */
    @Transactional
    public void review(Long shopId) {
        Shop shop = shopRepository.findById(shopId).orElse(null);
        if (shop == null || !shop.isTrusted()) {
            return; // shop thường vốn đã phải chờ duyệt tin
        }
        Instant since = Instant.now().minus(config.days(SystemConfigService.SHOP_REPUTATION_WINDOW_DAYS));
        long total = orderRepository.countByShopIdAndCreatedAtAfter(shopId, since);
        long faults = orderRepository.countByShopIdAndSellerFaultTrueAndCreatedAtAfter(shopId, since);
        BigDecimal rate = config.decimal(SystemConfigService.SHOP_FAULT_RATE_PERCENT);
        if (total < config.integer(SystemConfigService.SHOP_FAULT_MIN_ORDERS)
                || BigDecimal.valueOf(faults).multiply(BigDecimal.valueOf(100)).compareTo(rate.multiply(BigDecimal.valueOf(total))) < 0) {
            return;
        }
        shop.setTrusted(false);
        audit.record(EventCode.SHOP_TRUST_REVOKED, "SHOP", shopId, null, "Gỡ uy tín shop vì tỷ lệ đơn lỗi vượt ngưỡng",
                "faults", faults, "orders", total, "thresholdPercent", rate);
        notifications.notify(shop.getUserId(), NotificationService.LISTING, "Shop bị gỡ uy tín",
                "Tỷ lệ đơn lỗi của shop (" + faults + "/" + total + " đơn gần đây) vượt ngưỡng nên tin đăng mới cần chờ Admin duyệt",
                Map.of("shopId", shopId));
    }
}
