package com.rebook.auction;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ProxyBidRepository extends JpaRepository<ProxyBid, Long> {

    Optional<ProxyBid> findByLotIdAndUserId(Long lotId, Long userId);

    /** Giá tối đa cao nhất trước, bằng nhau thì ai đặt trước được ưu tiên. */
    List<ProxyBid> findByLotIdAndActiveTrueOrderByMaxAmountDescCreatedAtAsc(Long lotId);

    @Modifying
    @Query("update ProxyBid p set p.active = false where p.lotId = :lotId and p.active = true")
    int deactivateAll(@Param("lotId") Long lotId);
}
