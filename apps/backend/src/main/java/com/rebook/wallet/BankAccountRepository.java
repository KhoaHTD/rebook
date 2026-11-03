package com.rebook.wallet;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface BankAccountRepository extends JpaRepository<BankAccount, Long> {

    /** Yêu thích đứng đầu, rồi tới lần dùng mới nhất. */
    List<BankAccount> findByUserIdOrderByFavoriteDescLastUsedAtDesc(Long userId);

    Optional<BankAccount> findByUserIdAndBankNameAndAccountNumber(Long userId, String bankName, String accountNumber);
}
