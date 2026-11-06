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
    public static final String RETURN_RESPONSE_DAYS = "order.return_response_days";
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
    public static final String COD_MAX_AMOUNT = "order.cod_max_amount";
    public static final String COD_NEW_BUYER_MAX_AMOUNT = "order.cod_new_buyer_max_amount";
    public static final String COD_MAX_FAILURES = "order.cod_max_failures";
    public static final String COD_FAILURE_WINDOW_DAYS = "order.cod_failure_window_days";
    public static final String AUTO_DELIVER_DAYS = "order.auto_deliver_days";
    public static final String RETURN_SHIP_DAYS = "order.return_ship_days";
    public static final String RETURN_CONFIRM_DAYS = "order.return_confirm_days";
    public static final String TOPUP_HOLD_HOURS = "wallet.topup_hold_hours";
    public static final String WITHDRAW_DAILY_LIMIT = "wallet.withdraw_daily_limit";
    public static final String SELLER_HOLD_DAYS = "wallet.seller_hold_days";
    public static final String SELLER_HOLD_MIN_ORDERS = "wallet.seller_hold_min_orders";
    public static final String SELLER_HOLD_SHOP_DAYS = "wallet.seller_hold_shop_days";
    public static final String DEFAULT_PENALTY_PERCENT = "auction.default_penalty_percent";
    public static final String UNSOLD_DECISION_DAYS = "auction.unsold_decision_days";
    public static final String SHIP_DEADLINE_DAYS = "order.ship_deadline_days";
    public static final String CANCEL_RESPONSE_HOURS = "order.cancel_response_hours";
    public static final String SHOP_FAULT_RATE_PERCENT = "shop.fault_rate_percent";
    public static final String SHOP_FAULT_MIN_ORDERS = "shop.fault_min_orders";
    public static final String SHOP_REPUTATION_WINDOW_DAYS = "shop.reputation_window_days";
    public static final String REMINDER_HOURS = "notify.reminder_hours";
    public static final String WAREHOUSE_ADDRESS = "shipping.warehouse_address";
    public static final String MIN_PUBLISH_LEAD_HOURS = "auction.min_publish_lead_hours";
    public static final String MIN_REGISTRATION_CLOSE_HOURS = "auction.min_registration_close_hours";
    public static final String COMPENSATION_CAP_UNINSPECTED = "warehouse.compensation_cap_uninspected";
    public static final String COMPENSATION_BUYER_PERCENT = "warehouse.compensation_buyer_percent";
    public static final String CONSIGN_SELLER_DECISION_DAYS = "consignment.seller_decision_days";
    public static final String WAREHOUSE_ABANDON_DAYS = "warehouse.abandon_days";
    public static final String HIGH_VALUE_LOT_THRESHOLD = "auction.high_value_lot_threshold";
    public static final String HIGH_VALUE_DEPOSIT_PERCENT = "auction.high_value_deposit_percent";
    public static final String AUCTION_BAN_DAYS_REPEAT = "auction.ban_days_repeat";

    /** Mức nhỏ nhất của khoá số nguyên: đặt 0 là phá luật (vd thời hạn thanh toán 0 phút thì mọi đơn bị huỷ ngay). Khoá khác: ≥ 0. */
    private static final Map<String, Integer> MIN_VALUES = Map.ofEntries(
            Map.entry(BID_LIMIT_MULTIPLIER, 1),
            Map.entry(PAYMENT_TIMEOUT_MIN, 5),
            Map.entry(CONFIRM_TIMEOUT_HOURS, 1),
            Map.entry(AUTO_COMPLETE_DAYS, 1),
            Map.entry(RETURN_RESPONSE_DAYS, 1),
            Map.entry(AUTO_DELIVER_DAYS, 1),
            Map.entry(RETURN_SHIP_DAYS, 1),
            Map.entry(RETURN_CONFIRM_DAYS, 1),
            Map.entry(SHIP_DEADLINE_DAYS, 1),
            Map.entry(CANCEL_RESPONSE_HOURS, 1),
            Map.entry(AUCTION_PAYMENT_HOURS, 1),
            Map.entry(SECOND_CHANCE_HOURS, 1),
            Map.entry(CONSIGN_APPOINTMENT_DAYS, 1),
            Map.entry(CONSIGN_MAX_ROUNDS, 1),
            Map.entry(UNSOLD_DECISION_DAYS, 1),
            Map.entry(CONSIGN_SELLER_DECISION_DAYS, 1),
            Map.entry(AUCTION_BAN_DAYS_REPEAT, 1),
            Map.entry(WAREHOUSE_ABANDON_DAYS, 14)); // phải dài hơn 7 ngày báo trước khi thanh lý

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
        return bidIncrement(get(BID_TIERS), currentPrice);
    }

    /** Bước giá theo một bảng bậc cụ thể (bảng đã chốt vào phiên lúc công bố). */
    public static BigDecimal bidIncrement(String tierSpec, BigDecimal currentPrice) {
        TreeMap<BigDecimal, BigDecimal> tiers = new TreeMap<>();
        for (String part : tierSpec.split(",")) {
            String[] kv = part.trim().split(":");
            tiers.put(new BigDecimal(kv[0].trim()), new BigDecimal(kv[1].trim()));
        }
        Map.Entry<BigDecimal, BigDecimal> tier = tiers.floorEntry(currentPrice);
        return tier == null ? tiers.firstEntry().getValue() : tier.getValue();
    }

    public List<SystemConfig> all() {
        return repository.findAll();
    }

    /** Kiểm giá trị theo loại khoá; trả về giá trị đã cắt khoảng trắng. */
    private String validate(String key, String value) {
        String v = value == null ? "" : value.trim();
        try {
            if (key.equals(AUTO_APPROVE_TRUSTED)) {
                if (!v.equals("true") && !v.equals("false")) throw new IllegalArgumentException("true/false");
            } else if (key.equals(WAREHOUSE_PROVINCE) || key.equals(WAREHOUSE_ADDRESS)) {
                if (v.isEmpty()) throw new IllegalArgumentException("không được rỗng");
            } else if (key.equals(BID_TIERS)) {
                BigDecimal prev = null;
                for (String part : v.split(",")) {
                    String[] kv = part.trim().split(":");
                    BigDecimal from = new BigDecimal(kv[0].trim());
                    BigDecimal step = new BigDecimal(kv[1].trim());
                    if (kv.length != 2 || from.signum() < 0 || step.signum() <= 0 || (prev != null && from.compareTo(prev) <= 0)) {
                        throw new IllegalArgumentException("dạng từ_giá:bước, tăng dần");
                    }
                    prev = from;
                }
            } else if (key.endsWith("_percent")) {
                BigDecimal p = new BigDecimal(v);
                if (p.signum() < 0 || p.compareTo(BigDecimal.valueOf(100)) > 0) throw new IllegalArgumentException("0–100");
            } else {
                int min = MIN_VALUES.getOrDefault(key, 0);
                if (Integer.parseInt(v) < min) throw new IllegalArgumentException("số nguyên ≥ " + min);
            }
        } catch (RuntimeException e) {
            throw ApiException.badRequest("INVALID_CONFIG", "Giá trị không hợp lệ cho " + key + " (" + e.getMessage() + ")");
        }
        return v;
    }

    @Transactional
    public SystemConfig update(String key, String value) {
        SystemConfig config = repository.findById(key).orElseThrow(() -> ApiException.notFound("cấu hình " + key));
        value = validate(key, value);
        config.setValue(value);
        cache.remove(key);
        return repository.save(config);
    }
}
