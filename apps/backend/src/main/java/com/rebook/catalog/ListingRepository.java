package com.rebook.catalog;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface ListingRepository extends JpaRepository<Listing, Long>, JpaSpecificationExecutor<Listing> {

    @Override
    @EntityGraph(attributePaths = {"book", "shop"})
    Page<Listing> findAll(Specification<Listing> spec, Pageable pageable);

    @EntityGraph(attributePaths = {"book", "book.images", "shop"})
    Optional<Listing> findWithDetailsById(Long id);

    Optional<Listing> findByBookId(Long bookId);

    /**
     * Giữ hàng chống tranh chấp: chỉ trừ khi còn đủ tồn kho.
     * Trả về 0 nếu không đủ hàng (người khác vừa mua) hoặc tin không còn bán.
     */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE listings
               SET stock = stock - :qty,
                   sold_count = sold_count + :qty,
                   status = CASE WHEN stock - :qty = 0 THEN 'OUT_OF_STOCK' ELSE status END,
                   version = version + 1,
                   updated_at = now()
             WHERE id = :id AND status = 'ACTIVE' AND stock >= :qty
            """, nativeQuery = true)
    int reserveStock(@Param("id") Long id, @Param("qty") int qty);

    /** Hoàn tồn kho khi huỷ đơn / trả hàng. */
    @Modifying(flushAutomatically = true)
    @Query(value = """
            UPDATE listings
               SET stock = stock + :qty,
                   sold_count = GREATEST(sold_count - :qty, 0),
                   status = CASE WHEN status = 'OUT_OF_STOCK' THEN 'ACTIVE' ELSE status END,
                   version = version + 1,
                   updated_at = now()
             WHERE id = :id
            """, nativeQuery = true)
    int restoreStock(@Param("id") Long id, @Param("qty") int qty);

    long countByStatus(ListingStatus status);
}
