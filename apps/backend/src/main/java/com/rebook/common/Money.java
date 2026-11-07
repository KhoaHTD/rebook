package com.rebook.common;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.text.NumberFormat;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

/** Tiền VNĐ: BigDecimal scale 0, không dùng double. */
public final class Money {

    private Money() {
    }

    public static BigDecimal of(long value) {
        return BigDecimal.valueOf(value);
    }

    public static BigDecimal percent(BigDecimal amount, BigDecimal percent) {
        return amount.multiply(percent).divide(BigDecimal.valueOf(100), 0, RoundingMode.HALF_UP);
    }

    /** Số tiền cho người đọc: 640.000đ (dấu chấm ngăn cách hàng nghìn). */
    public static String vnd(BigDecimal amount) {
        return NumberFormat.getIntegerInstance(Locale.forLanguageTag("vi-VN")).format(amount) + "đ";
    }

    private static final DateTimeFormatter VN_TIME = DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy").withZone(ZoneId.of("Asia/Ho_Chi_Minh"));

    /** Giờ Việt Nam cho người đọc: 11:34 09/11/2026. */
    public static String vnTime(Instant at) {
        return VN_TIME.format(at);
    }

    public static BigDecimal nz(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }
}
