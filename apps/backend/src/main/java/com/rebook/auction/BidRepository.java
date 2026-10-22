package com.rebook.auction;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;

public interface BidRepository extends JpaRepository<Bid, Long> {

    /** Các lượt trả giá của lần đấu hiện tại (lô có thể đã đấu ở phiên trước). */
    @Query("select b from Bid b where b.lotId = :lotId and b.createdAt >= :since order by b.amount desc, b.id desc")
    List<Bid> findRecent(@Param("lotId") Long lotId, @Param("since") Instant since, Pageable pageable);

    /** Người trả giá cao nhất khác người đang thắng (mời mua lần hai). */
    @Query("""
            select b from Bid b where b.lotId = :lotId and b.createdAt >= :since and b.userId <> :excludeUserId
            order by b.amount desc, b.id asc
            """)
    List<Bid> findTopExcluding(@Param("lotId") Long lotId, @Param("since") Instant since,
                               @Param("excludeUserId") Long excludeUserId, Pageable pageable);
}
