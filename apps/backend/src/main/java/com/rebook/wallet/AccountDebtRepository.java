package com.rebook.wallet;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AccountDebtRepository extends JpaRepository<AccountDebt, Long> {

    List<AccountDebt> findByUserIdAndStatusOrderByIdAsc(Long userId, AccountDebt.Status status);

    List<AccountDebt> findByUserIdOrderByIdDesc(Long userId);

    boolean existsByUserIdAndStatus(Long userId, AccountDebt.Status status);

    /** Phần sàn giữ từ tiền phạt đã thu của các hoá đơn lô này (sau khi chia cho người bán nếu có). */
    @org.springframework.data.jpa.repository.Query("""
            select coalesce(sum(d.paidAmount * (100 - d.beneficiaryPercent) / 100), 0)
            from AccountDebt d, com.rebook.order.Order o
            where d.type = com.rebook.wallet.AccountDebt.Type.AUCTION_PENALTY and d.refType = 'ORDER'
              and d.refId = o.id and o.lotId = :lotId""")
    java.math.BigDecimal platformPenaltyCollectedForLot(@org.springframework.data.repository.query.Param("lotId") Long lotId);
}
