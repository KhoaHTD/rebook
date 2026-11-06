package com.rebook.consignment;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface WarehouseItemRepository extends JpaRepository<WarehouseItem, Long> {

    Optional<WarehouseItem> findByConsignmentId(Long consignmentId);

    @Query("""
            select w from WarehouseItem w where (:status is null or w.status = :status)
            order by w.checkedInAt desc
            """)
    Page<WarehouseItem> search(@Param("status") WarehouseItem.Status status, Pageable pageable);

    /** Sách chờ người bán nhận lại từ trước mốc này mà chưa được nhắc sắp thanh lý. */
    @Query("""
            select w.id from WarehouseItem w where w.status = com.rebook.consignment.WarehouseItem.Status.IN_STOCK
              and w.returnNotifiedAt < :before and w.abandonWarnedAt is null
            """)
    java.util.List<Long> findAbandonWarningIds(@Param("before") java.time.Instant before);

    /** Sách đã được nhắc sắp thanh lý từ trước mốc này mà người bán vẫn chưa nhận. */
    @Query("""
            select w.id from WarehouseItem w where w.status = com.rebook.consignment.WarehouseItem.Status.IN_STOCK
              and w.returnNotifiedAt is not null and w.abandonWarnedAt < :warnedBefore
            """)
    java.util.List<Long> findAbandonedIds(@Param("warnedBefore") java.time.Instant warnedBefore);
}
