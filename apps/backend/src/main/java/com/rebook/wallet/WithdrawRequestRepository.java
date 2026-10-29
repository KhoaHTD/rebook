package com.rebook.wallet;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface WithdrawRequestRepository extends JpaRepository<WithdrawRequest, Long> {

    List<WithdrawRequest> findByUserIdOrderByIdDesc(Long userId);

    Page<WithdrawRequest> findByStatusOrderByIdDesc(WithdrawRequest.Status status, Pageable pageable);

    /** Khoá dòng để hai Admin không cùng duyệt một yêu cầu. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select w from WithdrawRequest w where w.id = :id")
    Optional<WithdrawRequest> findByIdForUpdate(@Param("id") Long id);
}
