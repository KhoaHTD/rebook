package com.rebook.wallet;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface PaymentRepository extends JpaRepository<Payment, Long> {

    Optional<Payment> findByCode(String code);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Payment p where p.code = :code")
    Optional<Payment> lockByCode(@Param("code") String code);

    @Query("select p from Payment p where p.status = 'PENDING' and p.expiresAt < :now")
    List<Payment> findExpired(@Param("now") Instant now);
}
