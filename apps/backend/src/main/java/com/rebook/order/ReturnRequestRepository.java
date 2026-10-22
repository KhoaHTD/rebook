package com.rebook.order;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ReturnRequestRepository extends JpaRepository<ReturnRequest, Long> {

    Optional<ReturnRequest> findByOrderId(Long orderId);

    Page<ReturnRequest> findByStatusOrderByIdAsc(ReturnRequest.Status status, Pageable pageable);
}
