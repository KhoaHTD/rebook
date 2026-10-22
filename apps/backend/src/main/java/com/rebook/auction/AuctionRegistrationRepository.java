package com.rebook.auction;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface AuctionRegistrationRepository extends JpaRepository<AuctionRegistration, Long> {

    Optional<AuctionRegistration> findBySessionIdAndUserId(Long sessionId, Long userId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from AuctionRegistration r where r.sessionId = :sessionId and r.userId = :userId")
    Optional<AuctionRegistration> lockBySessionIdAndUserId(@Param("sessionId") Long sessionId, @Param("userId") Long userId);

    List<AuctionRegistration> findBySessionIdAndStatus(Long sessionId, AuctionRegistration.Status status);

    List<AuctionRegistration> findBySessionId(Long sessionId);

    List<AuctionRegistration> findByUserIdOrderByIdDesc(Long userId);

    long countBySessionIdAndStatusIn(Long sessionId, Collection<AuctionRegistration.Status> statuses);

    @Query("select coalesce(max(r.paddleNumber), 0) from AuctionRegistration r where r.sessionId = :sessionId")
    int maxPaddle(@Param("sessionId") Long sessionId);
}
