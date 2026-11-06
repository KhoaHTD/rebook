package com.rebook.consignment;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import jakarta.persistence.LockModeType;
import java.util.Optional;

public interface WarehouseIncidentRepository extends JpaRepository<WarehouseIncident, Long> {

    Page<WarehouseIncident> findByStatusOrderByIdDesc(WarehouseIncident.Status status, Pageable pageable);

    Page<WarehouseIncident> findAllByOrderByIdDesc(Pageable pageable);

    boolean existsByWarehouseItemIdAndStatus(Long warehouseItemId, WarehouseIncident.Status status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select i from WarehouseIncident i where i.id = :id")
    Optional<WarehouseIncident> lockById(@Param("id") Long id);
}
