package com.rebook.order;

/**
 * Phát đồng bộ (cùng transaction) mỗi khi đơn đổi trạng thái.
 * {@link OrderSettlement} xử lý tiền cho đơn NORMAL; module auction xử lý đơn AUCTION.
 */
public record OrderStatusChangedEvent(Order order, OrderStatus from, OrderStatus to, Long actorId) {
}
