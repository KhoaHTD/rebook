package com.rebook.system;

import com.rebook.common.ApiException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Đọc cấu hình phí, thời hạn, bước giá từ bảng system_configs (Admin sửa được).
 * Giữ cache trong bộ nhớ, làm mới khi Admin cập nhật.
 */
@Service
@RequiredArgsConstructor
public class SystemConfigService {

    // Khoá cấu hình dùng trong code
    public static final String FIXED_PRICE_FEE = "fee.fixed_price_percent";
    public static final String BUYER_PREMIUM = "fee.buyer_premium_percent";
    public static final String SELLER_COMMISSION = "fee.seller_commission_percent";
    public static final String STORAGE_PER_DAY = "fee.storage_per_day";
    public static final String STORAGE_FREE_DAYS = "fee.storage_free_days";
    public static final String PAYMENT_TIMEOUT_MIN = "order.payment_timeout_minutes";
    public static final String CONFIRM_TIMEOUT_HOURS = "order.confirm_timeout_hours";
    public static final String AUTO_COMPLETE_DAYS = "order.auto_complete_days";
    public static final String SHIP_SAME_PROVINCE = "shipping.same_province";
    public static final String SHIP_OTHER_PROVINCE = "shipping.other_province";
    public static final String SHIP_EXTRA_PER_500G = "shipping.extra_per_500g";
    public static final String WAREHOUSE_PROVINCE = "shipping.warehouse_province";
    public static final String CONSIGN_MIN_PRICE = "consignment.min_expected_price";
    public static final String CONSIGN_APPOINTMENT_DAYS = "consignment.appointment_days";
    public static final String CONSIGN_MAX_ROUNDS = "consignment.max_rounds";
    public static final String BID_TIERS = "auction.bid_increment_tiers";
    public static final String BID_LIMIT_MULTIPLIER = "auction.bid_limit_multiplier";
    public static final String AUCTION_PAYMENT_HOURS = "auction.payment_hours";
    public static final String SECOND_CHANCE_HOURS = "auction.second_chance_hours";
    public static final String AUCTION_BAN_DAYS = "auction.ban_days";
    public static final String FORFEIT_SELLER_PERCENT = "auction.forfeit_seller_percent";
    public static final String POSTPONE_DAYS = "auction.postpone_days";
    public static final String AUTO_APPROVE_TRUSTED = "listing.auto_approve_trusted";

    private final SystemConfigRepository repository;
    private final Map<String, String> cache = new ConcurrentHashMap<>();

    public String get(String key) {
        return cache.computeIfAbsent(key, k -> repository.findById(k)
                .map(SystemConfig::getValue)
                .orElseThrow(() -> new IllegalStateException("Thiếu cấu hình " + k)));
    }

    public BigDecimal decimal(String key) {
        return new BigDecimal(get(key).trim());
    }

    public int integer(String key) {
        return Integer.parseInt(get(key).trim());
    }

    public boolean bool(String key) {
        return Boolean.parseBoolean(get(key).trim());
    }

    public Duration minutes(String key) {
        return Duration.ofMinutes(integer(key));
    }

    public Duration hours(String key) {
        return Duration.ofHours(integer(key));
    }

    public Duration days(String key) {
        return Duration.ofDays(integer(key));
    }

    /** Bước giá theo bậc, ví dụ "0:10000,200000:50000" → {0: 10000, 200000: 50000}. */
    public BigDecimal bidIncrement(BigDecimal currentPrice) {
        TreeMap<BigDecimal, BigDecimal> tiers = new TreeMap<>();
        for (String part : get(BID_TIERS).split(",")) {
            String[] kv = part.trim().split(":");
            tiers.put(new BigDecimal(kv[0].trim()), new BigDecimal(kv[1].trim()));
        }
        Map.Entry<BigDecimal, BigDecimal> tier = tiers.floorEntry(currentPrice);
        return tier == null ? tiers.firstEntry().getValue() : tier.getValue();
    }

    public List<SystemConfig> all() {
        return repository.findAll();
    }

    @Transactional
    public SystemConfig update(String key, String value) {
        SystemConfig config = repository.findById(key).orElseThrow(() -> ApiException.notFound("cấu hình " + key));
        config.setValue(value);
        cache.remove(key);
        return repository.save(config);
    }
}
