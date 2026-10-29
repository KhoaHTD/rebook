package com.rebook.wallet;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface WithdrawTransferRepository extends JpaRepository<WithdrawTransfer, Long> {

    Optional<WithdrawTransfer> findByWithdrawId(Long withdrawId);

    List<WithdrawTransfer> findByWithdrawIdIn(Collection<Long> withdrawIds);
}
