package com.rebook.order;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ReviewRepository extends JpaRepository<Review, Long> {

    boolean existsByOrderId(Long orderId);

    Page<Review> findByShopIdOrderByIdDesc(Long shopId, Pageable pageable);

    @Query("select coalesce(avg(r.rating), 0) from Review r where r.shopId = :shopId")
    double averageForShop(@Param("shopId") Long shopId);

    long countByShopId(Long shopId);
}
