package com.rebook.common;

import java.math.BigDecimal;
import java.math.RoundingMode;

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

    public static BigDecimal nz(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }
}
