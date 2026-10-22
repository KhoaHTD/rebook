package com.rebook.wallet;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface WithdrawRequestRepository extends JpaRepository<WithdrawRequest, Long> {

    List<WithdrawRequest> findByUserIdOrderByIdDesc(Long userId);

    Page<WithdrawRequest> findByStatusOrderByIdAsc(WithdrawRequest.Status status, Pageable pageable);
}
