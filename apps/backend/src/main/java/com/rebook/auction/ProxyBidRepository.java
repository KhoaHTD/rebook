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

    /** Huỷ giá tối đa tự động của một người ở mọi lô của một phiên (khi huỷ đăng ký). */
    @Modifying
    @Query("update ProxyBid p set p.active = false where p.userId = :userId and p.active = true "
            + "and p.lotId in (select l.id from Lot l where l.sessionId = :sessionId)")
    int deactivateForUserInSession(@Param("userId") Long userId, @Param("sessionId") Long sessionId);
}
