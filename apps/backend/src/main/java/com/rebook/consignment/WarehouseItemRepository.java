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
}
