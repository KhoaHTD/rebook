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

    boolean existsByIdAndBuyerId(Long id, Long buyerId);

    long countByStatusIn(Collection<OrderStatus> statuses);

    @Query("select coalesce(sum(o.total), 0) from Order o where o.status = com.rebook.order.OrderStatus.COMPLETED and o.completedAt >= :from")
    BigDecimal sumCompletedSince(@Param("from") Instant from);

    @Query("select count(o) from Order o where o.createdAt >= :from")
    long countCreatedSince(@Param("from") Instant from);
}
