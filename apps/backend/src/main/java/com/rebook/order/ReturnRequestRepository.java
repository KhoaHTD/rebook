package com.rebook.order;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface ReturnRequestRepository extends JpaRepository<ReturnRequest, Long> {

    Optional<ReturnRequest> findByOrderId(Long orderId);

    Page<ReturnRequest> findByStatusOrderByIdAsc(ReturnRequest.Status status, Pageable pageable);

    Page<ReturnRequest> findByResolvedByIsNotNullOrderByResolvedAtDesc(Pageable pageable);

    /** Đã được đồng ý trả từ trước thời điểm này mà người mua vẫn chưa gửi hàng về. */
    @Query("""
            select r.orderId from ReturnRequest r
            where r.status = com.rebook.order.ReturnRequest.Status.AWAITING_GOODS
              and r.returnShippedAt is null and r.approvedAt < :before
            """)
    List<Long> findNotShippedOrderIds(@Param("before") Instant before);

    /** Người mua đã gửi hàng về từ trước thời điểm này mà shop / kho chưa xác nhận đã nhận. */
    @Query("""
            select r.orderId from ReturnRequest r
            where r.status = com.rebook.order.ReturnRequest.Status.AWAITING_GOODS
              and r.returnShippedAt is not null and r.returnShippedAt < :before
            """)
    List<Long> findShippedUnconfirmedOrderIds(@Param("before") Instant before);

    /** Đơn có yêu cầu trả hàng mà người bán chưa trả lời từ trước thời điểm này. */
    @Query("""
            select r.orderId from ReturnRequest r
            where r.status = com.rebook.order.ReturnRequest.Status.PENDING and r.createdAt < :before
            """)
    List<Long> findUnansweredOrderIds(@Param("before") Instant before);
}
