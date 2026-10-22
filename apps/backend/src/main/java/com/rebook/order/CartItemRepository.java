package com.rebook.order;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    List<CartItem> findByUserIdOrderByIdDesc(Long userId);

    Optional<CartItem> findByUserIdAndListingId(Long userId, Long listingId);

    void deleteByUserIdAndListingIdIn(Long userId, Collection<Long> listingIds);

    void deleteByUserId(Long userId);
}
