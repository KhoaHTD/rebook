package com.rebook.wallet;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AccountDebtRepository extends JpaRepository<AccountDebt, Long> {

    List<AccountDebt> findByUserIdAndStatusOrderByIdAsc(Long userId, AccountDebt.Status status);

    List<AccountDebt> findByUserIdOrderByIdDesc(Long userId);

    boolean existsByUserIdAndStatus(Long userId, AccountDebt.Status status);
}
