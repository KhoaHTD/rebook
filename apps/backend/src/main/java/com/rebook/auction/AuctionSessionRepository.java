package com.rebook.auction;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface AuctionSessionRepository extends JpaRepository<AuctionSession, Long> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from AuctionSession s where s.id = :id")
    Optional<AuctionSession> lockById(@Param("id") Long id);

    Page<AuctionSession> findByStatusInOrderByStartAtAsc(Collection<SessionStatus> statuses, Pageable pageable);

    Page<AuctionSession> findAllByOrderByStartAtDesc(Pageable pageable);

    @Query("select s.id from AuctionSession s where s.status = com.rebook.auction.SessionStatus.PUBLISHED and s.registrationDeadline <= :now")
    List<Long> findRegistrationClosed(@Param("now") Instant now);

    @Query("select s.id from AuctionSession s where s.status = com.rebook.auction.SessionStatus.CONFIRMED and s.startAt <= :now")
    List<Long> findDueToStart(@Param("now") Instant now);

    @Query("""
            select s.id from AuctionSession s where s.status = com.rebook.auction.SessionStatus.CONFIRMED
              and s.reminderSent = false and s.startAt <= :soon
            """)
    List<Long> findNeedReminder(@Param("soon") Instant soon);

    @Query("select s.id from AuctionSession s where s.status = com.rebook.auction.SessionStatus.LIVE")
    List<Long> findLiveIds();

    long countByStatus(SessionStatus status);
}
