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

    /** Tổng tiền người dùng đã yêu cầu rút (đang chờ hoặc đã duyệt) từ một thời điểm, để áp hạn mức mỗi ngày. */
    @Query("""
            select coalesce(sum(w.amount), 0) from WithdrawRequest w
            where w.userId = :userId and w.createdAt >= :since
              and w.status in (com.rebook.wallet.WithdrawRequest.Status.PENDING, com.rebook.wallet.WithdrawRequest.Status.APPROVED)
            """)
    java.math.BigDecimal sumRequestedSince(@Param("userId") Long userId, @Param("since") java.time.Instant since);

    /** Khoá dòng để hai Admin không cùng duyệt một yêu cầu. */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select w from WithdrawRequest w where w.id = :id")
    Optional<WithdrawRequest> findByIdForUpdate(@Param("id") Long id);
}
