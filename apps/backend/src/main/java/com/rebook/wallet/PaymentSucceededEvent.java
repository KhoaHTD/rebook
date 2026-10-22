package com.rebook.wallet;

/**
 * Phát ra (đồng bộ, cùng transaction) khi một payment thành công.
 * Module order lắng nghe để chuyển các đơn liên quan sang PENDING_CONFIRM.
 */
public record PaymentSucceededEvent(Payment payment) {
}
