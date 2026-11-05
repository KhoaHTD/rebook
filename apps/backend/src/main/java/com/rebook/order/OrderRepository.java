package com.rebook.order;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from Order o where o.id = :id")
    Optional<Order> lockById(@Param("id") Long id);

    @Query("""
            select o from Order o
            where o.buyerId = :buyerId and (:status is null or o.status = :status)
            order by o.createdAt desc
            """)
    Page<Order> findForBuyer(@Param("buyerId") Long buyerId, @Param("status") OrderStatus status, Pageable pageable);

    @Query("""
            select o from Order o
            where o.shopId = :shopId and (:status is null or o.status = :status)
            order by o.createdAt desc
            """)
    Page<Order> findForShop(@Param("shopId") Long shopId, @Param("status") OrderStatus status, Pageable pageable);

    @Query("""
            select o from Order o
            where o.orderType = com.rebook.order.Order.Type.AUCTION and (:status is null or o.status = :status)
            order by o.createdAt desc
            """)
    Page<Order> findAuctionOrders(@Param("status") OrderStatus status, Pageable pageable);

    List<Order> findByPaymentId(Long paymentId);

    /** Hoá đơn đấu giá còn hiệu lực của một người trong một phiên, theo thứ tự lập (để gộp phí giao). */
    @Query("""
            select o from Order o
            where o.orderType = com.rebook.order.Order.Type.AUCTION and o.buyerId = :buyerId
              and o.status <> com.rebook.order.OrderStatus.CANCELLED
              and o.lotId in (select l.id from Lot l where l.sessionId = :sessionId)
            order by o.id
            """)
    List<Order> findAuctionOrdersInSession(@Param("buyerId") Long buyerId, @Param("sessionId") Long sessionId);

    List<Order> findByLotIdAndStatusNot(Long lotId, OrderStatus status);

    @Query("""
            select o.id from Order o where o.orderType = com.rebook.order.Order.Type.NORMAL
              and o.status = com.rebook.order.OrderStatus.PENDING_PAYMENT and o.paymentDueAt < :now
            """)
    List<Long> findUnpaidNormalOrderIds(@Param("now") Instant now);

    @Query("""
            select o.id from Order o where o.orderType = com.rebook.order.Order.Type.NORMAL
              and o.status = com.rebook.order.OrderStatus.PENDING_CONFIRM and o.confirmDueAt < :now
            """)
    List<Long> findUnconfirmedOrderIds(@Param("now") Instant now);

    @Query("""
            select o.id from Order o where o.status = com.rebook.order.OrderStatus.DELIVERED and o.deliveredAt < :before
            """)
    List<Long> findDeliveredBefore(@Param("before") Instant before);

    @Query("""
            select o.id from Order o where o.orderType = com.rebook.order.Order.Type.AUCTION
              and o.status = com.rebook.order.OrderStatus.PENDING_PAYMENT and o.paymentDueAt < :now
            """)
    List<Long> findOverdueAuctionOrderIds(@Param("now") Instant now);

    /** Đơn đang giao từ trước thời điểm này mà người mua chưa xác nhận: tự coi là đã giao. */
    @Query("""
            select o.id from Order o where o.status = com.rebook.order.OrderStatus.SHIPPING and o.shippedAt < :before
              and (o.paymentMethod is null or o.paymentMethod <> com.rebook.wallet.Payment.Method.COD)
            """)
    List<Long> findShippedBefore(@Param("before") Instant before);

    /** Số đơn COD của người mua giao thất bại từ một thời điểm (để chặn người bom hàng). */
    @Query("""
            select count(o) from Order o
            where o.buyerId = :buyerId and o.paymentMethod = com.rebook.wallet.Payment.Method.COD
              and o.status = com.rebook.order.OrderStatus.FAILED_DELIVERY and o.cancelledAt >= :since
            """)
    long countCodFailuresSince(@Param("buyerId") Long buyerId, @Param("since") Instant since);

    long countByBuyerIdAndStatus(Long buyerId, OrderStatus status);

    /** Đơn COD đã giao nhưng sàn chưa nhận tiền đối soát (cũ nhất trước). */
    @Query("""
            select o from Order o
            where o.paymentMethod = com.rebook.wallet.Payment.Method.COD and o.codRemittedAt is null
              and o.status in (com.rebook.order.OrderStatus.DELIVERED, com.rebook.order.OrderStatus.COMPLETED,
                               com.rebook.order.OrderStatus.RETURN_REQUESTED, com.rebook.order.OrderStatus.RETURNED)
            order by o.deliveredAt asc
            """)
    Page<Order> findCodAwaitingRemittance(Pageable pageable);

    /** Đơn PREPARING quá hạn giao cho vận chuyển (bỏ qua đơn đang có yêu cầu huỷ chờ shop trả lời). */
    @Query("""
            select o.id from Order o
            where o.orderType = com.rebook.order.Order.Type.NORMAL and o.status = com.rebook.order.OrderStatus.PREPARING
              and o.pickupAtWarehouse = false and o.cancelRequested = false and o.shipDueAt < :now
            """)
    List<Long> findOverdueToShipIds(@Param("now") Instant now);

    /** Yêu cầu huỷ của người mua mà shop chưa trả lời từ trước thời điểm này. */
    @Query("""
            select o.id from Order o
            where o.status = com.rebook.order.OrderStatus.PREPARING and o.cancelRequested = true and o.cancelRequestedAt < :before
            """)
    List<Long> findUnansweredCancelRequestIds(@Param("before") Instant before);

    long countByShopIdAndCreatedAtAfter(Long shopId, Instant since);

    long countByShopIdAndSellerFaultTrueAndCreatedAtAfter(Long shopId, Instant since);

    /** Đơn của shop chưa giao cho vận chuyển (dọn khi khoá tài khoản). */
    @Query("""
            select o.id from Order o
            where o.shopId = :shopId and o.orderType = com.rebook.order.Order.Type.NORMAL
              and o.status in (com.rebook.order.OrderStatus.PENDING_CONFIRM, com.rebook.order.OrderStatus.PREPARING)
            """)
    List<Long> findOpenSellerOrderIds(@Param("shopId") Long shopId);

    /** Đơn thường của người mua đang chờ thanh toán (dọn khi khoá tài khoản). Hoá đơn lô đấu giá đi theo luồng phạt riêng. */
    @Query("""
            select o.id from Order o
            where o.buyerId = :buyerId and o.orderType = com.rebook.order.Order.Type.NORMAL
              and o.status = com.rebook.order.OrderStatus.PENDING_PAYMENT
            """)
    List<Long> findUnpaidNormalOrderIdsOfBuyer(@Param("buyerId") Long buyerId);

    /** Đơn thường đang giao, cũ nhất trước: Staff đối chiếu với hãng vận chuyển. COD không tự coi là đã giao. */
    @Query("""
            select o from Order o
            where o.orderType = com.rebook.order.Order.Type.NORMAL and o.status = com.rebook.order.OrderStatus.SHIPPING
            order by o.shippedAt asc
            """)
    Page<Order> findNormalInTransit(Pageable pageable);

    @Query("""
            select o.id from Order o
            where o.orderType = com.rebook.order.Order.Type.NORMAL and o.status = com.rebook.order.OrderStatus.PREPARING
              and o.cancelRequested = false and o.shipReminderSent = false and o.shipDueAt > :now and o.shipDueAt < :before
            """)
    List<Long> findShipReminderIds(@Param("now") Instant now, @Param("before") Instant before);

    @Query("""
            select o.id from Order o
            where o.status = com.rebook.order.OrderStatus.PREPARING and o.cancelRequested = true
              and o.cancelReminderSent = false and o.cancelRequestedAt < :before
            """)
    List<Long> findCancelReminderIds(@Param("before") Instant before);

    @Query("""
            select o.id from Order o
            where o.orderType = com.rebook.order.Order.Type.AUCTION and o.status = com.rebook.order.OrderStatus.PENDING_PAYMENT
              and o.paymentReminderSent = false and o.paymentDueAt > :now and o.paymentDueAt < :before
            """)
    List<Long> findPaymentReminderIds(@Param("now") Instant now, @Param("before") Instant before);

    boolean existsByIdAndBuyerId(Long id, Long buyerId);

    long countByStatusIn(Collection<OrderStatus> statuses);

    @Query("select coalesce(sum(o.total), 0) from Order o where o.status = com.rebook.order.OrderStatus.COMPLETED and o.completedAt >= :from")
    BigDecimal sumCompletedSince(@Param("from") Instant from);

    @Query("select count(o) from Order o where o.createdAt >= :from")
    long countCreatedSince(@Param("from") Instant from);
}
