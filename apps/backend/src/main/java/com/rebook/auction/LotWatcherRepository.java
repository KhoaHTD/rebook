package com.rebook.auction;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface LotWatcherRepository extends JpaRepository<LotWatcher, LotWatcher.Key> {

    boolean existsByUserIdAndLotId(Long userId, Long lotId);

    List<LotWatcher> findByUserIdOrderByCreatedAtDesc(Long userId);

    @Query("select distinct w.userId from LotWatcher w where w.lotId in :lotIds")
    List<Long> findUserIdsByLotIds(@Param("lotIds") Collection<Long> lotIds);

    @Query("select w.lotId from LotWatcher w where w.userId = :userId and w.lotId in :lotIds")
    List<Long> findWatchedLotIds(@Param("userId") Long userId, @Param("lotIds") Collection<Long> lotIds);
}
