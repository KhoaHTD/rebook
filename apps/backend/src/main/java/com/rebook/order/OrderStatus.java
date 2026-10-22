package com.rebook.order;

import com.rebook.common.StatusFlow;

import java.util.EnumSet;
import java.util.Set;

/** Luồng trạng thái đơn hàng (dùng chung cho mua thường và lô đấu giá đã thắng). */
public enum OrderStatus implements StatusFlow<OrderStatus> {
    /** Chờ thanh toán online (15 phút; với lô đấu giá là 48h). */
    PENDING_PAYMENT,
    /** Chờ người bán (hoặc kho) xác nhận. */
    PENDING_CONFIRM,
    /** Đang đóng gói. */
    PREPARING,
    SHIPPING,
    /** Đã giao, trong 3 ngày khiếu nại. */
    DELIVERED,
    RETURN_REQUESTED,
    /** Xong, đã trả tiền người bán. */
    COMPLETED,
    CANCELLED,
    RETURNED,
    FAILED_DELIVERY;

    @Override
    public Set<OrderStatus> nextStates() {
        return switch (this) {
            case PENDING_PAYMENT -> EnumSet.of(PENDING_CONFIRM, CANCELLED);
            case PENDING_CONFIRM -> EnumSet.of(PREPARING, CANCELLED);
            // PREPARING → DELIVERED chỉ khi người thắng đấu giá nhận tại kho
            case PREPARING -> EnumSet.of(SHIPPING, DELIVERED, CANCELLED);
            case SHIPPING -> EnumSet.of(DELIVERED, FAILED_DELIVERY);
            case DELIVERED -> EnumSet.of(COMPLETED, RETURN_REQUESTED);
            case RETURN_REQUESTED -> EnumSet.of(RETURNED, COMPLETED);
            case COMPLETED, CANCELLED, RETURNED, FAILED_DELIVERY -> EnumSet.noneOf(OrderStatus.class);
        };
    }

    public boolean isFinal() {
        return nextStates().isEmpty();
    }
}
