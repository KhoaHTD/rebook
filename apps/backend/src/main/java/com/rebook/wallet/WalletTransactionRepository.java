package com.rebook.wallet;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Collection;
import java.util.Optional;

public interface WalletTransactionRepository extends JpaRepository<WalletTransaction, Long> {

    Page<WalletTransaction> findByWalletIdOrderByIdDesc(Long walletId, Pageable pageable);

    /** Tổng thay đổi số dư dùng được của các loại giao dịch từ một thời điểm (có dấu). */
    @Query("""
            select coalesce(sum(t.availableChange), 0) from WalletTransaction t
            where t.walletId = :walletId and t.type in :types and t.createdAt >= :since
            """)
    BigDecimal sumAvailableChange(@Param("walletId") Long walletId, @Param("types") Collection<WalletTxType> types,
                                  @Param("since") Instant since);

    /** Lần nạp đầu tiên kể từ một thời điểm (để biết bao giờ tiền nạp hết bị khoá). */
    Optional<WalletTransaction> findFirstByWalletIdAndTypeAndCreatedAtGreaterThanEqualOrderByCreatedAtAsc(
            Long walletId, WalletTxType type, Instant since);
}
